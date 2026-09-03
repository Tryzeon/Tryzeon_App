import { useEffect, useRef, useState } from "react";
import { ActionSheet, type SheetAction } from "../components/ActionSheet";
import { ConfirmDialog } from "../components/ConfirmDialog";
import { FullscreenViewer } from "../components/FullscreenViewer";
import { Overlay } from "../components/Overlay";
import { StyleSheet } from "../components/StyleSheet";
import { TryonPager } from "../components/TryonPager";
import { useTryonCoordinator } from "../hooks/useTryonCoordinator";
import { canShareToChat, shareImageToChat } from "../lib/liff";
import {
  currentEntry,
  currentImageUrl,
  currentPage,
  isAvatarPage,
  isCurrentTheAvatar,
} from "../state/gallery";
import { useAvatar } from "../state/AvatarProvider";
import { useGallery } from "../state/GalleryProvider";

type Popup =
  | { kind: "none" }
  | { kind: "menu" }
  | { kind: "style" }
  | { kind: "viewer"; imageUrl: string }
  | { kind: "confirm"; message: string; confirmLabel: string; onConfirm(): void };

const CLOSED: Popup = { kind: "none" };

export function Home() {
  const { state, dispatch } = useGallery();
  const avatar = useAvatar();

  const [popup, setPopup] = useState<Popup>(CLOSED);
  const tryon = useTryonCoordinator();

  const notice = state.notice;
  const notify = (message: string) => dispatch({ type: "notify", message });
  const dismiss = () => dispatch({ type: "dismissNotice" });

  // Keyed on notice.id rather than the content: two identical failures in a row
  // each get their own four seconds, otherwise the second would inherit what was
  // left of the first and be dismissed the moment it appears.
  const noticeId = notice?.id ?? null;
  useEffect(() => {
    if (noticeId === null) return;
    const timer = setTimeout(() => dispatch({ type: "dismissNotice" }), 4000);
    return () => clearTimeout(timer);
  }, [noticeId, dispatch]);

  const avatarInput = useRef<HTMLInputElement>(null);
  const garmentInput = useRef<HTMLInputElement>(null);

  const page = currentPage(state);
  const entry = currentEntry(state);
  const imageUrl = currentImageUrl(state);

  const product = entry?.product ?? null;

  async function replaceAvatar(file: File) {
    if (!await avatar.replace(file)) {
      notify("照片上傳失敗，換一張清楚的全身照再試。");
      return;
    }
    dispatch({ type: "setPage", page: 0 });
  }

  async function share() {
    if (imageUrl === null) return;
    if (!canShareToChat()) {
      notify("這個環境不支援分享，長按圖片可以儲存到相簿。");
      return;
    }
    try {
      await shareImageToChat(imageUrl);
    } catch {
      notify("分享失敗，請稍後再試。");
    }
  }

  function confirmRemove(id: string, message: string, confirmLabel: string) {
    setPopup({
      kind: "confirm",
      message,
      confirmLabel,
      onConfirm: () => dispatch({ type: "remove", id }),
    });
  }

  const style: SheetAction = {
    title: "自訂試穿風格",
    subtitle: "指定場景與穿搭細節",
    onSelect: () => setPopup({ kind: "style" }),
  };
  const replace: SheetAction = {
    title: "更換模特圖片",
    subtitle: "上傳照片更換試穿模特",
    onSelect: () => avatarInput.current?.click(),
  };

  function menuActions(): SheetAction[] {
    if (entry === null) return [replace, style];

    if (entry.kind === "pending") {
      return [
        replace,
        style,
        {
          title: "取消生成",
          subtitle: "停止等待這次試穿結果",
          destructive: true,
          onSelect: () => confirmRemove(entry.id, "確定要取消這次試穿嗎？", "取消生成"),
        },
      ];
    }

    const id = entry.id;
    return [
      { title: "分享", subtitle: "傳到 LINE 聊天室", onSelect: share },
      {
        title: "儲存",
        subtitle: "長按圖片可存到相簿",
        onSelect: () => notify("長按畫面上的照片，就能儲存到相簿。"),
      },
      {
        title: isCurrentTheAvatar(state) ? "取消我的形象" : "設為我的形象",
        subtitle: isCurrentTheAvatar(state)
          ? "取消使用此照片作為試穿形象"
          : "使用此照片作為試穿形象",
        onSelect: () => dispatch({ type: "toggleAvatar" }),
      },
      replace,
      style,
      {
        title: "刪除此試穿",
        subtitle: "移除這張試穿照片",
        destructive: true,
        onSelect: () => confirmRemove(id, "確定要刪除這張試穿照片嗎？", "刪除"),
      },
    ];
  }

  return (
    <div className="app home">
      <TryonPager
        entries={state.entries}
        avatarUrl={avatar.url}
        avatarBusy={avatar.status === "loading" || avatar.busy}
        page={page}
        onPageChange={(next) => dispatch({ type: "setPage", page: next })}
        onAvatarTap={() => avatarInput.current?.click()}
        onResultTap={(url) => setPopup({ kind: "viewer", imageUrl: url })}
      />

      <div className="home__top">
        <span className="home__mark">Tryzeon</span>
        <div className="home__topright">
          {isCurrentTheAvatar(state) && (
            <span className="home__badge" aria-label="目前的試穿形象">★</span>
          )}
          <button
            type="button"
            className="home__more"
            aria-label="更多選項"
            onClick={() => setPopup({ kind: "menu" })}
          >
            ⋮
          </button>
        </div>
      </div>

      {!isAvatarPage(state) && (
        <div className="home__bottomleft">
          {product !== null && (
            <p className="home__caption"><b>{product.name}</b></p>
          )}
          <div className="dots">
            {state.entries.map((e, i) => (
              <span
                key={e.id}
                className={`dots__dot${page - 1 === i ? " is-active" : ""}`}
              />
            ))}
          </div>
          <p className="home__disclaimer">AI 生成試穿結果，僅供參考</p>
        </div>
      )}

      <div className="home__actions">
        <button
          type="button"
          className="home__cta"
          disabled={avatar.busy}
          onClick={() =>
            avatar.hasAvatar ? garmentInput.current?.click() : avatarInput.current?.click()}
        >
          {avatar.hasAvatar ? "虛擬試穿" : "上傳照片"}
        </button>
      </div>

      {avatar.status === "error" && (
        <p className="home__loadfail">模特照載入失敗，重新整理再試。</p>
      )}

      {/* Mounted on <body>: home stays mounted, but switching tabs hides the
          whole pane, so a message left inside it is never seen — switch to the
          shop while generating and a failure would give no feedback at all. */}
      {notice !== null && (
        <Overlay>
          <div className="toast" role="status" onClick={dismiss}>{notice.message}</div>
        </Overlay>
      )}

      <PickerInput inputRef={avatarInput} onPick={replaceAvatar} />
      <PickerInput inputRef={garmentInput} onPick={tryon.fromGarmentPhoto} />

      {popup.kind === "menu" && (
        <ActionSheet actions={menuActions()} onClose={() => setPopup(CLOSED)} />
      )}
      {popup.kind === "style" && <StyleSheet onClose={() => setPopup(CLOSED)} />}
      {popup.kind === "viewer" && (
        <FullscreenViewer imageUrl={popup.imageUrl} onClose={() => setPopup(CLOSED)} />
      )}
      {popup.kind === "confirm" && (
        <ConfirmDialog
          message={popup.message}
          confirmLabel={popup.confirmLabel}
          cancelLabel="取消"
          onConfirm={() => {
            popup.onConfirm();
            setPopup(CLOSED);
          }}
          onCancel={() => setPopup(CLOSED)}
        />
      )}
    </div>
  );
}

/** Clears the value after each pick, otherwise choosing the same photo twice
 * in a row never fires onChange again. */
function PickerInput(
  { inputRef, onPick }: {
    inputRef: React.RefObject<HTMLInputElement>;
    onPick(file: File): void;
  },
) {
  return (
    <input
      ref={inputRef}
      type="file"
      accept="image/*"
      hidden
      onChange={(e) => {
        const file = e.target.files?.[0];
        e.target.value = "";
        if (file) onPick(file);
      }}
    />
  );
}
