class AdService {
  static Future<List<String>> getAdImages({bool forceRefresh = false}) async {
    if (forceRefresh) {
      // clear cache
    }
    
    return [
      'assets/images/ads/gu.jpg',
      'assets/images/ads/net.png',
      'assets/images/ads/zara.jpg',
    ];
  }
}
