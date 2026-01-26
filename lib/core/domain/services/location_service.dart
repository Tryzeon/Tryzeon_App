import 'package:tryzeon/core/domain/entities/user_location.dart';

/// 位置服務抽象介面
abstract class LocationService {
  /// 取得使用者所在城市和區
  /// 若無法取得位置（權限拒絕、定位失敗等），返回 null
  Future<UserLocation?> getUserLocation();
}
