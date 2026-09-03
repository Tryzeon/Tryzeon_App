import { Overlay } from "./Overlay";

interface Props {
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm(): void;
  onCancel(): void;
}

/**
 * Drawn by hand instead of `window.confirm` — the native dialog blocks the
 * whole webview's event loop, and inside LINE it is especially hard to dismiss.
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
