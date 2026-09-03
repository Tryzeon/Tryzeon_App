import { useState } from "react";
import type { SortOption } from "../api/catalog";

const SORTS: { value: SortOption; label: string }[] = [
  { value: "latest", label: "最新" },
  { value: "price_asc", label: "價格低到高" },
  { value: "price_desc", label: "價格高到低" },
];

interface Props {
  sort: SortOption;
  onSearch(q: string): void;
  onSortChange(sort: SortOption): void;
  disabled?: boolean;
}

export function SearchSortBar({ sort, onSearch, onSortChange, disabled = false }: Props) {
  // Nothing is fetched until the form is submitted, so typing never fires a
  // request and no debounce is needed.
  const [draft, setDraft] = useState("");

  return (
    <div className="searchbar">
      <form
        className="searchbar__form"
        onSubmit={(e) => {
          e.preventDefault();
          onSearch(draft.trim());
        }}
      >
        <div className="searchbar__field">
          {/* `text` 而不是 `search`:原生的清除鍵按下去只改值、不送事件,React 也
              沒把 `search` 事件開出來,所以那顆叉叉沒辦法直接套用。自己畫一顆。 */}
          <input
            className="searchbar__input"
            type="text"
            value={draft}
            placeholder="搜尋商品"
            disabled={disabled}
            onChange={(e) => setDraft(e.target.value)}
          />
          {draft !== "" && (
            <button
              type="button"
              className="searchbar__clear"
              aria-label="清除搜尋"
              disabled={disabled}
              onClick={() => {
                setDraft("");
                onSearch("");
              }}
            >
              ✕
            </button>
          )}
        </div>
        <button className="searchbar__submit" type="submit" disabled={disabled}>搜尋</button>
      </form>
      <div className="chiprow">
        {SORTS.map((option) => (
          <button
            key={option.value}
            type="button"
            className={`sortchip${sort === option.value ? " is-active" : ""}`}
            aria-pressed={sort === option.value}
            disabled={disabled}
            onClick={() => onSortChange(option.value)}
          >
            {option.label}
          </button>
        ))}
      </div>
    </div>
  );
}
