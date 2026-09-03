typedef GeoCoordinates = ({double latitude, double longitude});

/// 將地址文字轉成經緯度的服務。
abstract class GeocodingService {
  /// 把 [address] geocode 成座標。
  /// 失敗(空字串、無結果、平台錯誤)時回傳 null。
  Future<GeoCoordinates?> geocodeAddress(final String address);
}
