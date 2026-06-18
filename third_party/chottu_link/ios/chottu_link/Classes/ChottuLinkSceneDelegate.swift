import UIKit

/// Forwards UIScene Universal Link events to `ChottuLinkPlugin`.
///
/// This object is registered dynamically at runtime so pod install order
/// cannot disable scene delegate support in CI.
final class ChottuLinkSceneDelegate: NSObject {
    @objc(scene:willConnectToSession:options:)
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
        guard let connectionOptions = connectionOptions else { return false }
        var handled = self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        for userActivity in connectionOptions.userActivities {
            handled = self.scene(scene, continue: userActivity) || handled
        }
        return handled
    }

    @objc(scene:openURLContexts:)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        guard !URLContexts.isEmpty else { return false }
        // LOCAL FORK PATCH: only claim ChottuLink-owned hosts; leave the app's own
        // schemes/links (tryzeon.com, com.tryzeon.app://) for Flutter/app_links.
        var handled = false
        for context in URLContexts where ChottuLinkHostFilter.isChottuLinkURL(context.url) {
            ChottuLinkPlugin.routeIncomingURL(context.url, source: "sceneOpenURLContexts")
            handled = true
        }
        return handled
    }

    @objc(scene:continueUserActivity:)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }
        // LOCAL FORK PATCH: only claim ChottuLink-owned hosts; pass tryzeon.com
        // Universal Links through to Flutter -> go_router.
        guard ChottuLinkHostFilter.isChottuLinkURL(url) else { return false }
        ChottuLinkPlugin.routeIncomingURL(url, source: "sceneContinueUserActivity")
        return true
    }
}
