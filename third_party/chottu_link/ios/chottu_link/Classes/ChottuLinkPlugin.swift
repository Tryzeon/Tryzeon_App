@preconcurrency import Flutter
import UIKit
import ChottuLinkSDK

/// Thread-safe buffer for URLs that arrive before the plugin registers (cold start + UIScene).
private enum IncomingLinkBuffer {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var urls: [URL] = []

    static func append(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        let key = url.absoluteString
        if !urls.contains(where: { $0.absoluteString == key }) {
            urls.append(url)
        }
    }

    static func drain() -> [URL] {
        lock.lock()
        defer { lock.unlock() }
        let pending = urls
        urls.removeAll()
        return pending
    }
}

@MainActor
public class ChottuLinkPlugin: NSObject, @preconcurrency FlutterPlugin, ChottuLinkDelegate, FlutterApplicationLifeCycleDelegate, @preconcurrency FlutterStreamHandler {

    private static weak var pluginInstance: ChottuLinkPlugin?
    private let sceneDelegate = ChottuLinkSceneDelegate()

    var eventSink: FlutterEventSink?
    /// Mirrors Android `getApiKey()`; the iOS SDK does not expose a static accessor.
    private var storedApiKey: String?
    private var isSdkInitialized = false
    private var lastHandledURLKey: String?
    private var lastHandledAt: Date = .distantPast
    private let duplicateWindowSeconds: TimeInterval = 1.5
    /// Universal link URLs received before Flutter calls `init` (cold start).
    private var pendingIncomingURLs: [URL] = []
    /// Resolved link payload when Flutter EventChannel is not listening yet.
    private var pendingResolvedPayload: [String: Any]?

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        flushPendingResolvedPayload()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    public func chottuLink(didResolveDeepLink link: URL, metadata: [String : Any]?) {
        deliverToFlutter(makePayload(link: link, metadata: metadata))
    }

    public func chottuLink(didFailToResolveDeepLink originalURL: URL?, error: any Error) {
        print("ChottuLinkPlugin: Failed to resolve deep link \(originalURL?.absoluteString ?? "nil"): \(error.localizedDescription)")
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "chottu_link", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "chottu_link/events", binaryMessenger: registrar.messenger())
        let instance = ChottuLinkPlugin()
        Self.pluginInstance = instance

        for url in IncomingLinkBuffer.drain() {
            instance.enqueueIncomingLink(url)
        }

        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
        if #available(iOS 13.0, *) {
            Self.addSceneDelegateIfSupported(on: registrar, delegate: instance.sceneDelegate)
        }

        NotificationCenter.default.addObserver(
            instance,
            selector: #selector(instance.handleContinueUserActivity(notification:)),
            name: NSNotification.Name("ChottuLinkPluginNotify"),
            object: nil
        )
    }

    @objc func handleContinueUserActivity(notification: Notification) {
        if let userActivity = notification.userInfo?["userActivity"] as? NSUserActivity {
            guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                  let url = userActivity.webpageURL else { return }
            Self.routeIncomingURL(url, source: "handleContinueUserActivity")
        }
    }

    nonisolated public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }
        // LOCAL FORK PATCH: only claim ChottuLink-owned hosts; pass everything
        // else (e.g. tryzeon.com Universal Links) through to Flutter -> go_router.
        guard ChottuLinkHostFilter.isChottuLinkURL(url) else { return false }
        Self.routeIncomingURL(url, source: "applicationContinueUserActivity")
        return true
    }

    nonisolated static func routeIncomingURL(_ url: URL, source: String) {
        DispatchQueue.main.async {
            Task { @MainActor in
                if let instance = pluginInstance {
                    instance.enqueueIncomingLink(url)
                } else {
                    IncomingLinkBuffer.append(url)
                }
                print("ChottuLinkPlugin (\(source)): queued/handled \(url.absoluteString)")
            }
        }
    }

    private func enqueueIncomingLink(_ url: URL) {
        if shouldDropDuplicateIncomingURL(url) { return }
        let key = url.absoluteString
        if isSdkInitialized {
            ChottuLink.handleLink(url)
            return
        }
        if !pendingIncomingURLs.contains(where: { $0.absoluteString == key }) {
            pendingIncomingURLs.append(url)
        }
    }

    private func flushPendingIncomingLinks() {
        guard isSdkInitialized else { return }
        let urls = pendingIncomingURLs
        pendingIncomingURLs.removeAll()
        for url in urls {
            ChottuLink.handleLink(url)
        }
    }

    private static func addSceneDelegateIfSupported(on registrar: FlutterPluginRegistrar, delegate: NSObject) {
        let selector = NSSelectorFromString("addSceneDelegate:")
        guard let registrarObject = registrar as? NSObject else {
            print("ChottuLinkPlugin: registrar is not NSObject; scene delegate registration skipped.")
            return
        }
        guard registrarObject.responds(to: selector) else {
            print("ChottuLinkPlugin: addSceneDelegate unavailable on this Flutter version.")
            return
        }
        _ = registrarObject.perform(selector, with: delegate)
    }

    private func shouldDropDuplicateIncomingURL(_ url: URL) -> Bool {
        let key = url.absoluteString
        let now = Date()
        if lastHandledURLKey == key, now.timeIntervalSince(lastHandledAt) < duplicateWindowSeconds {
            print("ChottuLinkPlugin: dropping duplicate URL \(key)")
            return true
        }
        lastHandledURLKey = key
        lastHandledAt = now
        return false
    }

    private func makePayload(link: URL, metadata: [String: Any]?) -> [String: Any] {
        [
            "link": link.absoluteString,
            "shortLink": (metadata?["originalURL"] as? String) ?? "",
            "shortLinkRaw": (metadata?["shortLinkRaw"] as? String) ?? "",
            "isDeferred": (metadata?["isDeferred"] as? Bool) ?? false,
        ]
    }

    private func deliverToFlutter(_ payload: [String: Any]) {
        if let sink = eventSink {
            print("ChottuLinkPlugin: Sending link to Flutter: \(payload["link"] ?? "")")
            sink(payload)
            pendingResolvedPayload = nil
        } else {
            print("ChottuLinkPlugin: eventSink nil; caching resolved link for Flutter listener.")
            pendingResolvedPayload = payload
        }
    }

    private func flushPendingResolvedPayload() {
        guard let payload = pendingResolvedPayload, let sink = eventSink else { return }
        print("ChottuLinkPlugin: Flushing cached link to Flutter: \(payload["link"] ?? "")")
        sink(payload)
        pendingResolvedPayload = nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            guard let receivedApiKey = call.arguments as? String else {
                result(FlutterError(code: "INIT-1", message: "apiKey is required", details: nil))
                return
            }
            storedApiKey = receivedApiKey
            let config = CLConfiguration(apiKey: receivedApiKey, isDebugEnabled: false, delegate: self)
            ChottuLink.initialize(config: config)
            isSdkInitialized = true
            flushPendingIncomingLinks()
            result("SDK INITIATED")

            return
        case "createDynamicLink":
            DispatchQueue.main.async {
                do{

                    guard let args = call.arguments as? [String: Any] else {
                        result(FlutterError(code: "CL-1", message: "Arguments are not a dictionary", details: nil))
                        return
                    }

                    var linkUrl = ""
                    var domain = ""


                    if let link = args["link"] as? String {
                        linkUrl = link
                    }

                    if let tempDomain = args["domain"] as? String {
                        domain = tempDomain
                    }


                    var params = CLDynamicLinkBuilder(destinationURL: linkUrl, domain: domain)


                    if let _androidBehaviour = args["androidBehaviour"] as? Int {
                        params = params.setAndroidBehaviour(_androidBehaviour == 1 ? CLDynamicLinkBehaviour.browser :CLDynamicLinkBehaviour.app)
                    }

                    if let _iosBehaviour = args["iosBehaviour"] as? Int {
                        params = params.setIOSBehaviour(_iosBehaviour == 1 ? CLDynamicLinkBehaviour.browser : CLDynamicLinkBehaviour.app)
                    }

                    if let _utmSource = args["utmSource"] as? String {
                        params = params.setUTMSource(_utmSource)
                    }

                    if let _utmMedium = args["utmMedium"] as? String {
                        params = params.setUTMMedium(_utmMedium)
                    }
                    if let _utmCampaign = args["utmCampaign"] as? String {
                        params = params.setUTMCampaign(_utmCampaign)
                    }

                    if let _utmContent = args["utmContent"] as? String {
                        params = params.setUTMContent(_utmContent)
                    }

                    if let _utmTerm = args["utmTerm"] as? String {
                        params = params.setUTMTerm(_utmTerm)
                    }


                    if let _linkName = args["linkName"] as? String {
                        params = params.setLinkName(_linkName)
                    }


                    if let _selectedPath = args["selectedPath"] as? String {
                        params = params.setSelectedPath(_selectedPath)
                    }


                    if let _socialDescription = args["socialDescription"] as? String {
                        params = params.setSocialDescription(_socialDescription)
                    }

                    if let _socialImageUrl = args["socialImageUrl"] as? String {
                        params = params.setSocialImageUrl(_socialImageUrl)
                    }

                    if let _socialTitle = args["socialTitle"] as? String {
                        params = params.setSocialTitle(_socialTitle)
                    }

                    ChottuLink.createDynamicLink(for: params.build()) { link, error in
                        if let error = error {
                            result(FlutterError(code: "CL-2", message: "Failed to create dynamic link: \(error.localizedDescription)", details: nil))
                        } else if let link = link {
                            result(link)
                        } else {
                            result(FlutterError(code: "UNKNOWN", message: "Failed to create dynamic link, no link or error returned.", details: nil))
                        }
                    }
                }catch{
                    result(FlutterError(code: "UNKNOWN", message: "Failed to create dynamic link, no link or error returned.", details: nil))
                }
            }
            return
        case "getAppLinkDataFromUrl":
            Task {
                do{
                    guard let shortLink = call.arguments as? String else {
                        result(FlutterError(code: "RL-1", message: "ShortLink is null for resolveDynamicLink", details: nil))
                        return
                    }

                    let data = try await ChottuLink.getAppLinkDataFromUrl(from: shortLink)
                    guard let link = data.link else {
                        result(FlutterError(code: "RL-2", message: "Error during resolve dynamic link: No Link found !!", details: nil))
                        return
                    }

                    var myMutableMap = [String: Any]()
                    myMutableMap["link"] = link.absoluteString
                    myMutableMap["shortLink"] = data.shortLink?.absoluteString
                    myMutableMap["shortLinkRaw"] = data.shortLinkRaw?.absoluteString
                    myMutableMap["isDeferred"] = data.isDeferred

                    result(myMutableMap)


                }catch{
                    result(FlutterError(code: "RL-3", message: "Failed to resolve dynamic link, no link or error returned. \(error.localizedDescription)", details: nil))
                }
            }
            return
        case "getAppLinkData":
            flushPendingIncomingLinks()
            flushPendingResolvedPayload()
            result(
                "Attempted to process pending link data. Listen to EventChannel ('chottu_link/events') for link results."
            )

        case "getApiKey":
            result(storedApiKey ?? "")

        case "getAttributionData":
            guard let data = ChottuLink.getAttributionData() else {
                result(nil)
                return
            }
            var map: [String: Any] = [:]
            map["attributionType"] = data.attributionType
            map["installId"] = data.installId
            map["matchFound"] = data.matchFound
            map["matchType"] = data.matchType
            map["shortUrl"] = data.shortUrl
            map["clickedShortUrl"] = data.clickedShortUrl
            map["destinationUrl"] = data.destinationUrl
            map["destinationWithUtm"] = data.destinationWithUtm
            map["utmSource"] = data.utmSource
            map["utmMedium"] = data.utmMedium
            map["utmCampaign"] = data.utmCampaign
            map["utmTerm"] = data.utmTerm
            map["utmContent"] = data.utmContent
            map["isAttributed"] = data.isAttributed
            result(map)

        case "identify":
            guard let args = Self.stringAnyMap(from: call.arguments) else {
                result(FlutterError(code: "ID-1", message: "identify args map is null", details: nil))
                return
            }
            guard let id = args["id"] as? String else {
                result(FlutterError(code: "ID-2", message: "id is required", details: nil))
                return
            }
            let meta = CLCustomerMeta(
                id: id,
                name: args["name"] as? String,
                email: args["email"] as? String,
                phone: args["phone"] as? String,
                emailSha256: args["emailSha256"] as? String,
                phoneSha256: args["phoneSha256"] as? String
            )
            ChottuLink.identify(meta)
            result(nil)

        case "trackLead":
            guard let args = Self.stringAnyMap(from: call.arguments) else {
                result(FlutterError(code: "TL-1", message: "trackLead args map is null", details: nil))
                return
            }
            let meta = CLLeadMeta(
                eventName: args["eventName"] as? String,
                metadata: Self.stringAnyMap(from: args["metadata"])
            )
            ChottuLink.trackLead(meta)
            result(nil)

        case "trackConversion":
            guard let args = Self.stringAnyMap(from: call.arguments) else {
                result(FlutterError(code: "TC-1", message: "trackConversion args map is null", details: nil))
                return
            }
            guard let revenue = Self.doubleValue(from: args["revenue"]) else {
                result(FlutterError(code: "TC-2", message: "revenue is missing or not a number", details: nil))
                return
            }
            let meta = CLConversionMeta(
                revenue: revenue,
                currency: args["currency"] as? String,
                eventName: args["eventName"] as? String,
                productId: args["productId"] as? String,
                transactionId: args["transactionId"] as? String,
                metadata: Self.stringAnyMap(from: args["metadata"])
            )
            ChottuLink.trackConversion(meta)
            result(nil)

        case "trackEvent":
            guard let args = Self.stringAnyMap(from: call.arguments) else {
                result(FlutterError(code: "TE-1", message: "trackEvent args map is null", details: nil))
                return
            }
            let name = args["eventName"] as? String ?? ""
            ChottuLink.trackEvent(name: name, data: Self.stringAnyMap(from: args["eventData"]))
            result(nil)

        case "flush":
            ChottuLink.flush()
            result(nil)

        case "logout":
            ChottuLink.logout()
            result(nil)

        case "optOut":
            let enabled = call.arguments as? Bool ?? false
            ChottuLink.optOut(enabled)
            result(nil)

        case "isOptedOut":
            result(ChottuLink.isOptedOut)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func stringAnyMap(from input: Any?) -> [String: Any]? {
        if let m = input as? [String: Any] { return m }
        guard let m = input as? [AnyHashable: Any] else { return nil }
        var out: [String: Any] = [:]
        for (k, v) in m {
            out[String(describing: k)] = v
        }
        return out
    }

    private static func doubleValue(from value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        return nil
    }
}
