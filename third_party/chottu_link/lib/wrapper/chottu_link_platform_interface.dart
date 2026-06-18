import 'package:chottu_link/dynamic_link/cl_dynamic_link_parameters.dart';
import 'package:chottu_link/model/chottu_link_error.dart';
import 'package:chottu_link/model/chottu_link_resolve_link.dart';
import 'package:chottu_link/wrapper/chottu_link_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class ChottuLinkPlatform extends PlatformInterface {
  /// Constructs a ChottuLinkPlatform.
  ChottuLinkPlatform() : super(token: _token);

  static final Object _token = Object();

  static ChottuLinkPlatform _instance = MethodChannelChottuLink();

  /// The default instance of [ChottuLinkPlatform] to use.
  ///
  /// Defaults to [MethodChannelChottuLink].
  static ChottuLinkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ChottuLinkPlatform] when
  /// they register themselves.
  static set instance(ChottuLinkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> init({required String apiKey}) {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Method to create a dynamic link, accepting a map of parameters.
  /// Should return a Future which is the short URL or null on error.
  void createDynamicLink(
      {required CLDynamicLinkParameters parameters,
      Function(String)? onSuccess,
      Function(ChottuLinkError)? onError}) {
    throw UnimplementedError('createDynamicLink() has not been implemented.');
  }

  Future<void> getAppLinkData() {
    throw UnimplementedError('createDynamicLink() has not been implemented.');
  }

  Future<void> getAppLinkDataFromUrl(
      {required String shortUrl,
      Function(ResolvedLink)? onSuccess,
      Function(ChottuLinkError)? onError}) {
    throw UnimplementedError(
        'getAppLinkDataFromUrl() has not been implemented.');
  }

  Future<String> getApiKey() {
    throw UnimplementedError('getApiKey() has not been implemented.');
  }

  /// Returns cached attribution data if available, otherwise `null`.
  Future<Map<dynamic, dynamic>?> getAttributionData() {
    throw UnimplementedError(
      'getAttributionData() has not been implemented.',
    );
  }

  Future<void> identify(Map<String, dynamic> meta) {
    throw UnimplementedError('identify() has not been implemented.');
  }

  Future<void> trackLead(Map<String, dynamic> meta) {
    throw UnimplementedError('trackLead() has not been implemented.');
  }

  Future<void> trackConversion(Map<String, dynamic> meta) {
    throw UnimplementedError('trackConversion() has not been implemented.');
  }

  Future<void> trackEvent(
    String eventName,
    Map<String, dynamic>? eventData,
  ) {
    throw UnimplementedError('trackEvent() has not been implemented.');
  }

  Future<void> flush() {
    throw UnimplementedError('flush() has not been implemented.');
  }

  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  Future<void> optOut(bool optOut) {
    throw UnimplementedError('optOut() has not been implemented.');
  }

  Future<bool> isOptedOut() {
    throw UnimplementedError('isOptedOut() has not been implemented.');
  }
}
