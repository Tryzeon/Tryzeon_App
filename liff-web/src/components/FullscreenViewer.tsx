import { Overlay } from "./Overlay";

interface Props {
  imageUrl: string;
  onClose(): void;
}

export function FullscreenViewer({ imageUrl, onClose }: Props) {
  return (
    <Overlay>
      <div className="viewer" role="dialog" aria-modal="true" onClick={onClose}>
        <img className="viewer__img" src={imageUrl} alt="試穿結果" />
        <button type="button" className="viewer__close" onClick={onClose} aria-label="關閉">
          ✕
        </button>
      </div>
    </Overlay>
  );
}
