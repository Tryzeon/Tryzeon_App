import { Overlay } from "./Overlay";

interface Props {
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm(): void;
  onCancel(): void;
}

/**
 * 破壞性動作前的確認。自己畫而不用 `window.confirm` —— 原生對話框會擋住整個
 * webview 的事件迴圈,在 LINE 裡尤其難收回來。
 */
export function ConfirmDialog(
  { message, confirmLabel, cancelLabel, onConfirm, onCancel }: Props,
) {
  return (
    <Overlay>
      <div className="sheet" role="dialog" aria-modal="true">
        <div className="sheet__backdrop" onClick={onCancel} />
        <div className="sheet__panel sheet__panel--menu">
          <div className="sheet__body">
            <p className="confirm__message">{message}</p>
            <button type="button" className="cta confirm__ok" onClick={onConfirm}>
              {confirmLabel}
            </button>
            <button type="button" className="btn-outline menu__cancel" onClick={onCancel}>
              {cancelLabel}
            </button>
          </div>
        </div>
      </div>
    </Overlay>
  );
}
