/** 純本地識別碼 —— 伺服器不知道它的存在,只需要在這個 session 內唯一。 */
export function newId(): string {
  return typeof crypto.randomUUID === "function"
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}
