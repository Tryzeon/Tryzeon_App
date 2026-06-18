/// Flutter representation of Android `ChottuLink.AttributionData`.
class AttributionData {
  final String? attributionType;
  final String? installId;
  final bool matchFound;
  final String? matchType;

  final String? shortUrl;
  final String? clickedShortUrl;
  final String? destinationUrl;
  final String? destinationWithUtm;

  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmTerm;
  final String? utmContent;

  final bool isAttributed;

  const AttributionData({
    this.attributionType,
    this.installId,
    required this.matchFound,
    this.matchType,
    this.shortUrl,
    this.clickedShortUrl,
    this.destinationUrl,
    this.destinationWithUtm,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmTerm,
    this.utmContent,
    required this.isAttributed,
  });

  factory AttributionData.fromMap(Map<dynamic, dynamic> map) {
    // Native returns `matchFound` and `isAttributed` as booleans when possible.
    final matchFound = (map['matchFound'] as bool?) ?? false;
    final isAttributed = (map['isAttributed'] as bool?) ??
        ((map['attributionType'] == 'ATTRIBUTED'));

    return AttributionData(
      attributionType: map['attributionType'] as String?,
      installId: map['installId'] as String?,
      matchFound: matchFound,
      matchType: map['matchType'] as String?,
      shortUrl: map['shortUrl'] as String?,
      clickedShortUrl: map['clickedShortUrl'] as String?,
      destinationUrl: map['destinationUrl'] as String?,
      destinationWithUtm: map['destinationWithUtm'] as String?,
      utmSource: map['utmSource'] as String?,
      utmMedium: map['utmMedium'] as String?,
      utmCampaign: map['utmCampaign'] as String?,
      utmTerm: map['utmTerm'] as String?,
      utmContent: map['utmContent'] as String?,
      isAttributed: isAttributed,
    );
  }
}
