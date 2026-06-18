import Foundation

/// LOCAL FORK PATCH — not in upstream chottu_link 1.1.1.
///
/// Restricts ChottuLink's universal-link / custom-URL interception to
/// ChottuLink-owned hosts. Without this, the plugin claims (`return true`) every
/// `NSUserActivityTypeBrowsingWeb` activity and every opened URL, which swallows
/// the app's own `tryzeon.com` Universal Links before Flutter's built-in deep
/// linking can forward them to go_router.
///
/// Deferred deep linking is unaffected: it is delivered through the SDK's
/// install-attribution delegate (`chottuLink(didResolveDeepLink:metadata:)`),
/// not through the intercepted link callbacks gated here.
///
/// To add a custom ChottuLink domain, append its suffix to `allowedSuffixes`.
enum ChottuLinkHostFilter {
    static let allowedSuffixes = ["chottu.link"]

    static func isChottuLinkURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return allowedSuffixes.contains { host == $0 || host.hasSuffix(".\($0)") }
    }
}
