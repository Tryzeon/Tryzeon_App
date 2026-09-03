abstract class AuthIdentityService {
  /// 目前登入的使用者 id：先給啟動時還原的 session，之後每個認證事件各給一次。
  ///
  /// 刻意不去重複值。重複的 id 就是重試額度 —— 綁定身分的副作用失敗後，靠下一次
  /// token refresh 重新拿到同一個 id 就能復原，不必等使用者重新登入。
  Stream<String?> watchUserId();
}
