/**
 * The app's design system, as LINE renders it.
 *
 * `docs/ui-design-system.md` describes Clean Luxe in Flutter terms — a
 * ColorScheme, a type scale, an 8px grid. This module is that spec's LINE
 * dialect: the same tokens as hex, and the two button shapes the spec defines,
 * built the only way Flex can build them. It knows nothing about products, so
 * every surface this feature grows later can dress itself from here rather
 * than inventing a second charcoal.
 */

/** Card palette. Every value is a token from `docs/ui-design-system.md`. */
export const CARD_COLOR = {
  /** `onSurface` / `primary` — charcoal. Every high-emphasis element. */
  primary: "#1A1A1A",
  /** `onPrimary` — text on a charcoal fill. */
  onPrimary: "#FFFFFF",
  /** `onSurfaceVariant` — muted grey. Secondary text. */
  muted: "#9E9E9E",
  /** `outline` — the secondary button's border. */
  outline: "#E5E5E5",
  /** `background` — the card surface, pinned so no theme can move it. */
  surface: "#FFFFFF",
} as const;

/**
 * A filled charcoal button.
 *
 * A box rather than Flex's `button`, because `button` offers three fixed
 * styles — filled-coloured, filled-grey, text-only — and controls neither
 * corner radius nor type. The design system asks for an 8px radius and, for
 * `secondaryButton`, an outlined shape that `button` simply does not have. A
 * box carrying an `action` is tappable across its whole area, so both buttons
 * are built the same way and stay siblings.
 *
 * The action belongs on the box, never on the inner text: on the text only the
 * glyphs would be tappable.
 */
export function primaryButton(label: string, action: object): object {
  return {
    type: "box",
    layout: "vertical",
    action,
    backgroundColor: CARD_COLOR.primary,
    cornerRadius: "8px",
    paddingAll: "12px",
    contents: [{
      type: "text",
      text: label,
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.onPrimary,
      align: "center",
    }],
  };
}

/** An outlined button: the same shape, one emphasis level down. */
export function secondaryButton(label: string, action: object): object {
  return {
    type: "box",
    layout: "vertical",
    action,
    borderWidth: "1px",
    borderColor: CARD_COLOR.outline,
    cornerRadius: "8px",
    paddingAll: "12px",
    contents: [{
      type: "text",
      text: label,
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.primary,
      align: "center",
    }],
  };
}
