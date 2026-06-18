import 'dart:core';
import 'package:chottu_link/dynamic_link/cl_dynamic_link_behaviour.dart';

/// Parameters for creating a ChottuLink dynamic link.
///
/// This class holds all the information required to create a dynamic link,
/// including the deep link, domain, platform-specific behavior, and optional
/// tracking and social media parameters.
class CLDynamicLinkParameters {
  /// The underlying deep link that the dynamic link will open.
  /// This is typically a URL that points to a specific content within your app.
  final Uri link;

  /// The custom domain to use for the dynamic link.
  final String domain;

  /// The desired behavior on Android.
  /// Defaults to [CLDynamicLinkBehaviour.app], which attempts to open the app.
  final CLDynamicLinkBehaviour androidBehaviour;

  /// The desired behavior on iOS.
  /// Defaults to [CLDynamicLinkBehaviour.app], which attempts to open the app.
  final CLDynamicLinkBehaviour iosBehaviour;

  /// The `utm_source` parameter for tracking.
  final String? utmSource;

  /// The `utm_medium` parameter for tracking.
  final String? utmMedium;

  /// The `utm_campaign` parameter for tracking.
  final String? utmCampaign;

  /// The `utm_content` parameter for tracking.
  final String? utmContent;

  /// The `utm_term` parameter for tracking.
  final String? utmTerm;

  /// A name or identifier for the link.
  final String? linkName;

  /// The path to be appended to the dynamic link.
  final String? selectedPath;

  /// The description to be used when the link is shared on social media.
  final String? socialDescription;

  /// The URL of an image to be used when the link is shared on social media.
  final String? socialImageUrl;

  /// The title to be used when the link is shared on social media.
  final String? socialTitle;

  /// Creates an instance of [CLDynamicLinkParameters].
  CLDynamicLinkParameters({
    required this.link,
    required this.domain,
    this.androidBehaviour = CLDynamicLinkBehaviour.app,
    this.iosBehaviour = CLDynamicLinkBehaviour.app,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
    this.linkName,
    this.selectedPath,
    this.socialDescription,
    this.socialImageUrl,
    this.socialTitle,
  });

  /// Converts the parameters to a [Map] for use with the platform channel.
  /// This method is for internal use only.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> params = {
      'link': Uri.decodeFull(link.toString()),
      'domain': domain,
      'androidBehaviour':
          androidBehaviour == CLDynamicLinkBehaviour.browser ? 1 : 2,
      'iosBehaviour': iosBehaviour == CLDynamicLinkBehaviour.browser ? 1 : 2,
    };

    if (utmSource != null && utmSource!.isNotEmpty) {
      params['utmSource'] = utmSource;
    }
    if (utmMedium != null && utmMedium!.isNotEmpty) {
      params['utmMedium'] = utmMedium;
    }
    if (utmCampaign != null && utmCampaign!.isNotEmpty) {
      params['utmCampaign'] = utmCampaign;
    }
    if (utmContent != null && utmContent!.isNotEmpty) {
      params['utmContent'] = utmContent;
    }
    if (utmTerm != null && utmTerm!.isNotEmpty) {
      params['utmTerm'] = utmTerm;
    }
    if (linkName != null && linkName!.isNotEmpty) {
      params['linkName'] = linkName;
    }
    if (selectedPath != null && selectedPath!.isNotEmpty) {
      params['selectedPath'] = selectedPath;
    }
    if (socialDescription != null && socialDescription!.isNotEmpty) {
      params['socialDescription'] = socialDescription;
    }
    if (socialImageUrl != null && socialImageUrl!.isNotEmpty) {
      params['socialImageUrl'] = socialImageUrl;
    }
    if (socialTitle != null && socialTitle!.isNotEmpty) {
      params['socialTitle'] = socialTitle;
    }

    return params;
  }
}
