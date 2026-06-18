import 'dart:async';
import 'package:chottu_link/dynamic_link/cl_dynamic_link_parameters.dart';
import 'package:chottu_link/model/chottu_link_error.dart';
import 'package:chottu_link/model/chottu_link_resolve_link.dart';
import 'package:chottu_link/model/attribution_data.dart';
import 'package:chottu_link/model/conversion_meta.dart';
import 'package:chottu_link/model/customer_meta.dart';
import 'package:chottu_link/model/lead_meta.dart';
import 'package:chottu_link/wrapper/chottu_link_platform_interface.dart';
import 'package:flutter/services.dart';

class ChottuLink {
  static bool _isInitialized = false;
  static const EventChannel _channel = EventChannel('chottu_link/events');
  static final Stream<dynamic> _nativeRawEvents =
      _channel.receiveBroadcastStream().asBroadcastStream();

  static final Stream<ResolvedLink> _nativeLinkStream =
      _nativeRawEvents.map((event) {
    if (event is String) {
      return ResolvedLink(link: event);
    }
    if (event is Map) {
      final String? link = event['link'] as String?;
      final String? shortLink = event['shortLink'] as String?;
      final String? shortLinkRaw = event['shortLinkRaw'] as String?;
      final bool? isDeferred = event['isDeferred'] as bool?;
      return ResolvedLink(
          link: link,
          shortLink: shortLink,
          shortLinkRaw: shortLinkRaw,
          isDeferred: isDeferred);
    }
    return ResolvedLink(
        link: null, shortLink: null, shortLinkRaw: null, isDeferred: null);
  });

  static bool isInitialized() {
    return _isInitialized;
  }

  static Stream<ResolvedLink> get _onLinkReceivedFromNative =>
      _nativeLinkStream;

  static Stream<String> get onLinkReceived => _onLinkReceivedFromNative
      .map((event) => event.link ?? event.shortLink)
      .where((link) => link != null)
      .cast<String>();

  static Stream<ResolvedLink> get onLinkReceivedWithMeta =>
      _onLinkReceivedFromNative;

  /// Initializes the native ChottuLink SDK.
  /// Returns a Future that completes when the platform-side init call is done.
  static Future<void> init({required String apiKey}) async {
    // Assuming ChottuLinkPlatform.instance.init returns Future<String?> or similar
    // and we want to mark initialized only upon successful completion from platform.
    try {
      await ChottuLinkPlatform.instance.init(apiKey: apiKey);
      _isInitialized = true;
      // Log success or handle the returned value from platform if any
    } catch (e) {
      _isInitialized = false; // Explicitly set to false on error
      rethrow; // Or handle more gracefully
    }
  }

  /// Creates a dynamic link using the native ChottuLink SDK.
  ///
  /// Takes [DynamicLinkParameters] and returns the short URL as a String if successful,
  /// or null/throws an exception otherwise.
  static void createDynamicLink(
      {required CLDynamicLinkParameters parameters,
      Function(String)? onSuccess,
      Function(ChottuLinkError)? onError}) async {
    if (!_isInitialized) {
      throw StateError(
          'ChottuLink SDK has not been initialized. Call ChottuLink.init() first.');
    }
    try {
      ChottuLinkPlatform.instance.createDynamicLink(
          parameters: parameters, onSuccess: onSuccess, onError: onError);
    } catch (e) {
      rethrow; // Or return null or a custom error object
    }
  }

  static Future<void> getAppLinkDataFromUrl(
      {required String shortUrl,
      Function(ResolvedLink)? onSuccess,
      Function(ChottuLinkError)? onError}) async {
    try {
      if (!_isInitialized) {
        throw StateError(
            'ChottuLink SDK has not been initialized. Call ChottuLink.init() first.');
      }
      await ChottuLinkPlatform.instance.getAppLinkDataFromUrl(
          shortUrl: shortUrl, onSuccess: onSuccess, onError: onError);
    } catch (e) {
      rethrow; // Or handle more gracefully
    }
  }

  // =======================
  // Android-only parity APIs
  // =======================

  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'ChottuLink SDK has not been initialized. Call ChottuLink.init() first.',
      );
    }
  }

  static Future<String> getApiKey() async {
    _ensureInitialized();
    return ChottuLinkPlatform.instance.getApiKey();
  }

  static Future<AttributionData?> getAttributionData() async {
    _ensureInitialized();
    final Map<dynamic, dynamic>? raw =
        await ChottuLinkPlatform.instance.getAttributionData();
    if (raw == null) return null;
    return AttributionData.fromMap(raw);
  }

  static Future<void> identify(CustomerMeta meta) async {
    _ensureInitialized();
    await ChottuLinkPlatform.instance.identify(meta.toMap());
  }

  static Future<void> trackLead(LeadMeta meta) async {
    _ensureInitialized();
    await ChottuLinkPlatform.instance.trackLead(meta.toMap());
  }

  static Future<void> trackConversion(ConversionMeta meta) async {
    _ensureInitialized();
    await ChottuLinkPlatform.instance.trackConversion(meta.toMap());
  }

  static Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? eventData,
  }) async {
    _ensureInitialized();
    await ChottuLinkPlatform.instance.trackEvent(
      eventName,
      eventData,
    );
  }

  static Future<void> flush() async {
    _ensureInitialized();
    await ChottuLinkPlatform.instance.flush();
  }

  static Future<void> logout() async {
    _ensureInitialized();
    await ChottuLinkPlatform.instance.logout();
  }

  static Future<void> optOut(bool optOut) async {
    _ensureInitialized();
    await ChottuLinkPlatform.instance.optOut(optOut);
  }

  static Future<bool> isOptedOut() async {
    _ensureInitialized();
    return ChottuLinkPlatform.instance.isOptedOut();
  }
}
