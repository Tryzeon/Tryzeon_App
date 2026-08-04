class AdLocalDataSource {
  Future<List<String>> getAdImages({final bool forceRefresh = false}) async {
    // In a real app, logic for forceRefresh would be here (e.g., clearing local cache)
    return [
      'assets/images/ads/1.jpg',
      'assets/images/ads/2.jpg',
      'assets/images/ads/3.jpg',
      'assets/images/ads/4.jpg',
      'assets/images/ads/5.jpg',
      'assets/images/ads/6.jpg',
      'assets/images/ads/7.jpg',
      'assets/images/ads/8.jpg',
    ];
  }
}
