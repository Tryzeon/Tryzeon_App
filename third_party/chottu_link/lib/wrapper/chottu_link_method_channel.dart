import 'package:chottu_link/dynamic_link/cl_dynamic_link_parameters.dart';
import 'package:chottu_link/model/chottu_link_error.dart';
import 'package:chottu_link/model/chottu_link_resolve_link.dart';
import 'package:chottu_link/wrapper/chottu_link_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// An implementation of [ChottuLinkPlatform] that uses method channels.
class MethodChannelChottuLink extends ChottuLinkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('chottu_link');

  @override
  Future<String?> init({required String apiKey}) async {
    final String? result =
        await methodChannel.invokeMethod<String>('init', apiKey);
    return result;
  }

  /// Actual
  ///
  @override
  void createDynamicLink(
      {required CLDynamicLinkParameters parameters,
      Function(String)? onSuccess,
      Function(ChottuLinkError)? onError}) async {
    try {
      final Object? result = await methodChannel.invokeMethod<Object>(
        'createDynamicLink',
        parameters.toMap(),
      );
      if (result is String) {
        onSuccess?.call(result);
        return;
      }
    } on PlatformException catch (e) {
      onError?.call(ChottuLinkError(
          errorCode: e.code,
          message: e.message,
          description:
              "❌ Error While Creating Dynamic Link [${e.code}] - ${e.message}"));
    }
  }

  @override
  Future<void> getAppLinkData() async {
    final String? _ = await methodChannel.invokeMethod<String>(
      'getAppLinkData',
    );
  }

  @override
  Future<void> getAppLinkDataFromUrl(
      {required String shortUrl,
      Function(ResolvedLink)? onSuccess,
      Function(ChottuLinkError)? onError}) async {
    try {
      final Object? result = await methodChannel.invokeMethod<Object>(
        'getAppLinkDataFromUrl',
        shortUrl,
      );
      if (result is Map<Object?, Object?>) {
        String? link = result["link"] as String?;
        String? deepLinkUrl = result["shortLink"] as String?;
        String? shortLinkRaw = result["shortLinkRaw"] as String?;
        bool? isDeferred = result["isDeferred"] as bool?;

        var returnParams = ResolvedLink(
            link: link,
            shortLink: deepLinkUrl,
            shortLinkRaw: shortLinkRaw,
            isDeferred: isDeferred);
        onSuccess?.call(returnParams);
        return;
      }
    } on PlatformException catch (e) {
      onError?.call(ChottuLinkError(
          errorCode: e.code,
          message: e.message,
          description:
              "❌ Error While Resolve Dynamic Link [${e.code}] - ${e.message}"));
    }
  }

  @override
  Future<String> getApiKey() async {
    final String? result =
        await methodChannel.invokeMethod<String>('getApiKey');
    return result ?? '';
  }

  @override
  Future<Map<dynamic, dynamic>?> getAttributionData() async {
    final Object? result = await methodChannel.invokeMethod(
      'getAttributionData',
    );
    if (result == null) return null;
    if (result is Map) {
      return result.cast<dynamic, dynamic>();
    }
    return null;
  }

  @override
  Future<void> identify(Map<String, dynamic> meta) async {
    await methodChannel.invokeMethod('identify', meta);
  }

  @override
  Future<void> trackLead(Map<String, dynamic> meta) async {
    await methodChannel.invokeMethod('trackLead', meta);
  }

  @override
  Future<void> trackConversion(Map<String, dynamic> meta) async {
    await methodChannel.invokeMethod('trackConversion', meta);
  }

  @override
  Future<void> trackEvent(
    String eventName,
    Map<String, dynamic>? eventData,
  ) async {
    await methodChannel.invokeMethod('trackEvent', {
      'eventName': eventName,
      'eventData': eventData,
    });
  }

  @override
  Future<void> flush() async {
    await methodChannel.invokeMethod('flush');
  }

  @override
  Future<void> logout() async {
    await methodChannel.invokeMethod('logout');
  }

  @override
  Future<void> optOut(bool optOut) async {
    await methodChannel.invokeMethod('optOut', optOut);
  }

  @override
  Future<bool> isOptedOut() async {
    final bool? result = await methodChannel.invokeMethod<bool>('isOptedOut');
    return result ?? false;
  }
}
