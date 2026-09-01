/**
 * 一次試穿在 gallery 裡的識別碼。純本地 —— 伺服器不知道它的存在,所以只需要在這
 * 個 session 內唯一。
 */
export function newId(): string {
  return typeof crypto.randomUUID === "function"
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}
