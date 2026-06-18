/// Defines the behavior of a ChottuLink dynamic link when opened on a device.
enum CLDynamicLinkBehaviour {
  /// Tries to open the link in the corresponding app.
  /// If the app is not installed, it may fall back to the browser or App/Play Store.
  app,

  /// Forces the link to open in a web browser, even if the app is installed.
  browser
}
