import { useState } from "react";
import { Overlay } from "./Overlay";
import {
  loadPromptConfig,
  savePromptConfig,
  SCENE_PRESETS,
  STYLING_PRESETS,
  type PromptConfig,
} from "../lib/promptConfig";

interface Props {
  onClose(): void;
}

/** 轉場只影響影片,LIFF 沒有影片試穿,所以這裡只有兩段。 */
export function StyleSheet({ onClose }: Props) {
  const [config, setConfig] = useState<PromptConfig>(loadPromptConfig);

  function save() {
    savePromptConfig(config);
    onClose();
  }

  return (
    <Overlay>
      <div className="sheet" role="dialog" aria-modal="true" aria-label="自訂試穿風格">
        <div className="sheet__backdrop" onClick={onClose} />
        <div className="sheet__panel sheet__panel--menu">
          <div className="sheet__body">
            <h2 className="sheet__name">自訂試穿風格</h2>

            <Field
              label="穿搭細節 Styling"
              placeholder="例如：紮進褲頭"
              emptyLabel="不指定"
              presets={STYLING_PRESETS}
              value={config.stylingPrompt}
              onChange={(stylingPrompt) => setConfig({ ...config, stylingPrompt })}
            />

            <Field
              label="場景 Scene"
              placeholder="例如：純白攝影棚"
              emptyLabel="沿用原背景"
              presets={SCENE_PRESETS}
              value={config.scenePrompt}
              onChange={(scenePrompt) => setConfig({ ...config, scenePrompt })}
            />

            <button type="button" className="cta" onClick={save}>儲存</button>
          </div>
        </div>
      </div>
    </Overlay>
  );
}

interface FieldProps {
  label: string;
  placeholder: string;
  emptyLabel: string;
  presets: string[];
  value: string;
  onChange(value: string): void;
}

function Field({ label, placeholder, emptyLabel, presets, value, onChange }: FieldProps) {
  return (
    <div className="field">
      <p className="field__label">{label}</p>
      <div className="chiprow">
        <button
          type="button"
          className={`sortchip${value === "" ? " is-active" : ""}`}
          onClick={() => onChange("")}
        >
          {emptyLabel}
        </button>
        {presets.map((preset) => (
          <button
            key={preset}
            type="button"
            className={`sortchip${value === preset ? " is-active" : ""}`}
            onClick={() => onChange(preset)}
          >
            {preset}
          </button>
        ))}
      </div>
      <input
        className="searchbar__input field__input"
        type="text"
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
}
