/**
 * 這個人有沒有 model 照,一個 boolean。
 *
 * 進場時查一次(LiffGate),上傳成功時就地翻面(Onboard),中間不再問伺服器。
 * 狀態放在模組層而不是 React state,是因為讀它的地方(Shop 的試穿按鈕)和寫它
 * 的地方(Onboard)之間沒有共同的父元件,而為了一個 boolean 拉一個 context
 * 進來不划算。
 */
let onboarded = false;

export function isOnboarded(): boolean {
  return onboarded;
}

export function setOnboarded(value: boolean): void {
  onboarded = value;
}
