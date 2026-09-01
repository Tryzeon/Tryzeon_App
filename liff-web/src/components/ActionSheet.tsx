import { Overlay } from "./Overlay";

export interface SheetAction {
  title: string;
  subtitle: string;
  destructive?: boolean;
  onSelect(): void;
}

interface Props {
  actions: SheetAction[];
  onClose(): void;
}

/** 從底部升起的動作清單,對應 app 的 `showAppActionSheet`。 */
export function ActionSheet({ actions, onClose }: Props) {
  return (
    <Overlay>
      <div className="sheet" role="dialog" aria-modal="true" aria-label="更多選項">
        <div className="sheet__backdrop" onClick={onClose} />
        <div className="sheet__panel sheet__panel--menu">
          <ul className="menu">
            {actions.map((action) => (
              <li key={action.title}>
                <button
                  type="button"
                  className={`menu__item${action.destructive ? " is-destructive" : ""}`}
                  onClick={() => {
                    onClose();
                    action.onSelect();
                  }}
                >
                  <span className="menu__title">{action.title}</span>
                  <span className="menu__subtitle">{action.subtitle}</span>
                </button>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </Overlay>
  );
}
