# chottu_link — local fork patch notes

Vendored from `chottu_link` **1.1.1** (pub.dev) and wired in via
`dependency_overrides` in the app `pubspec.yaml`.

## Why

Upstream's native plugins claim **every** incoming Universal Link / App Link and
report it as handled, with no host filtering:

- iOS `ChottuLinkPlugin.application(_:continue:restorationHandler:)` → `return true`
- iOS `ChottuLinkSceneDelegate.scene(_:continue:)` and `scene(_:openURLContexts:)` → `return true`
- Android `ChottuLinkPlugin.onNewIntent(...)` → `return true`

Because our only iOS associated domain / Android App Link host is `tryzeon.com`,
the SDK was swallowing our own deep links before Flutter's built-in deep linking
(`FlutterDeepLinkingEnabled`) could forward them to go_router. Result: after
adding chottu_link, `tryzeon.com/s/{code}`, `/product/...`, `/store/...` stopped
navigating when the app was already installed.

## What changed

The interception points now only claim **ChottuLink-owned hosts** (`*.chottu.link`);
all other URLs return "not handled" so they fall through to Flutter → go_router
(and to `app_links` for the `com.tryzeon.app://` OAuth callback).

- `ios/chottu_link/Classes/ChottuLinkHostFilter.swift` — **new** allow-list helper.
- `ios/chottu_link/Classes/ChottuLinkPlugin.swift` — host-guard in `application(_:continue:)`.
- `ios/chottu_link/Classes/ChottuLinkSceneDelegate.swift` — host-guard in `scene(_:continue:)` and per-context filter in `scene(_:openURLContexts:)`.
- `android/.../ChottuLinkPlugin.kt` — `isChottuLinkIntent()` + guard in `onNewIntent()`.

Deferred deep linking is intentionally **untouched**:

- iOS deferred arrives via the SDK attribution delegate `chottuLink(didResolveDeepLink:metadata:)`, not the patched callbacks.
- Android deferred arrives via cold-start launch-intent `getAppLinkData` (Install Referrer match) in `onAttachedToActivity`/`onListen`, which we left unfiltered.

## Adding a custom ChottuLink domain

Add the suffix in two places:

- iOS: `ChottuLinkHostFilter.allowedSuffixes`
- Android: `CHOTTU_HOST_SUFFIXES`

## Re-applying on upgrade

When bumping chottu_link, re-copy the upstream package over this folder and
re-apply the four edits above (search for `LOCAL FORK PATCH`).
