/** Every value is a token from `docs/ui-design-system.md`. */
export const CARD_COLOR = {
  primary: "#1A1A1A",
  onPrimary: "#FFFFFF",
  muted: "#9E9E9E",
  outline: "#E5E5E5",
  surface: "#FFFFFF",
} as const;

/**
 * Flex's `button` offers three fixed styles and controls neither corner radius
 * nor type, so both buttons are boxes carrying an `action`, tappable across the
 * whole area. The action must sit on the box: on the inner text only the glyphs
 * would be tappable.
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
