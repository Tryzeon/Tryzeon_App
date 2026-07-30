interface Props {
  busy: boolean;
  onPick(file: File): void;
}

export function AvatarUploadPrompt({ busy, onPick }: Props) {
  return (
    <div className="avatarprompt">
      <p className="cta__hint">
        還沒有 model 照。上傳一張清楚的全身照，之後所有試穿都會用它。
      </p>
      <div className="tipcard">
        <span className="tipcard__icon" aria-hidden="true">💡</span>
        <p className="tipcard__text">
          建議上傳短袖短褲的正面全身照，雙手自然下垂、手上不要拿手機等物品。
        </p>
      </div>
      <label className={`cta${busy ? " is-loading" : ""}`}>
        {busy
          ? (
            <span className="cta__spin">
              <span className="spinner" aria-hidden="true" />
              上傳中…
            </span>
          )
          : "上傳我的 model 照"}
        <input
          type="file"
          accept="image/*"
          disabled={busy}
          onChange={(e) => {
            const file = e.target.files?.[0];
            if (file) onPick(file);
          }}
          style={{ display: "none" }}
        />
      </label>
    </div>
  );
}
