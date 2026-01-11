class AdLocalDataSource {
  Future<List<String>> getAdImages({final bool forceRefresh = false}) async {
    // In a real app, logic for forceRefresh would be here (e.g., clearing local cache)
    return [
      'assets/images/ads/gu.jpg',
      'assets/images/ads/net.png',
      'assets/images/ads/zara.jpg',
    ];
  }
}