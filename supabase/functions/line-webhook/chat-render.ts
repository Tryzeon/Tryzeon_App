/**
 * LINE has no equivalent of the core's ordered block list — it has messages, and
 * a bubble carousel is one message. So consecutive cards collapse into one
 * carousel and each text block stays its own message, preserving the ordering
 * the model meant for as long as it fits in a single send.
 */
import type { ContentBlock } from "../_shared/chat/index.ts";
import {
  clampProductName,
  type LineProduct,
  productInfoContents,
  purchaseAction,
} from "./product-card.ts";
import { garmentNoun, type LineWardrobeItem, wardrobeInfoContents } from "./wardrobe-card.ts";
import { CARD_COLOR, primaryButton, secondaryButton } from "./card-kit.ts";
import { chatErrorMessage } from "./messages.ts";
import { productTryonPostbackData, wardrobeTryonPostbackData } from "./postback.ts";
import { dressLast, messageChip } from "./quick-reply.ts";

const MAX_LINE_MESSAGES = 5;
/** LINE's carousel cap; a search returns at most 10, so this is slack. */
const MAX_BUBBLES = 12;
const MAX_TEXT_CHARS = 5000;

/** A union rather than two section kinds: the two sit side by side in one carousel. */
type LineCard =
  | { kind: "product"; item: LineProduct }
  | { kind: "wardrobe"; item: LineWardrobeItem };

type Section =
  | { kind: "text"; lines: string[] }
  | { kind: "cards"; items: LineCard[] };

function toSections(blocks: ContentBlock[]): Section[] {
  const sections: Section[] = [];

  const pushCard = (card: LineCard) => {
    const last = sections.at(-1);
    if (last?.kind === "cards") last.items.push(card);
    else sections.push({ kind: "cards", items: [card] });
  };

  for (const block of blocks) {
    if (block.type === "text") {
      const text = typeof block.text === "string" ? block.text : "";
      const last = sections.at(-1);
      if (last?.kind === "text") last.lines.push(text);
      else sections.push({ kind: "text", lines: [text] });
    } else if (block.type === "product") {
      pushCard({ kind: "product", item: block.item as LineProduct });
    } else if (block.type === "wardrobe") {
      pushCard({ kind: "wardrobe", item: block.item as LineWardrobeItem });
    }
  }
  return sections;
}

function textMessage(lines: string[]): object {
  return { type: "text", text: lines.join("\n").slice(0, MAX_TEXT_CHARS) };
}

function productBubble(product: LineProduct): object {
  const purchase = purchaseAction(product);
  const buttons: object[] = [
    primaryButton("試穿這件", {
      type: "postback",
      label: "試穿這件",
      data: productTryonPostbackData(product.id),
      // Clamped: `displayText` fails the whole send past 300 characters, and a
      // product name has no length constraint.
      displayText: `試穿「${clampProductName(product.name)}」`,
    }),
  ];
  if (purchase) {
    buttons.push(secondaryButton("前往購買", purchase));
  }

  return {
    type: "bubble",
    size: "kilo",
    hero: {
      type: "image",
      url: product.imageUrl,
      size: "full",
      aspectRatio: "1:1",
      aspectMode: "cover",
    },
    body: {
      type: "box",
      layout: "vertical",
      paddingAll: "16px",
      contents: productInfoContents(product),
    },
    footer: {
      type: "box",
      layout: "vertical",
      // `spacing` is the one gap here that cannot be stated in px: LINE accepts
      // only keywords for it, unlike `margin` and `padding`.
      spacing: "sm",
      paddingAll: "16px",
      paddingTop: "0px",
      contents: buttons,
    },
    styles: {
      body: { backgroundColor: CARD_COLOR.surface },
      footer: { backgroundColor: CARD_COLOR.surface },
    },
  };
}

/**
 * `fit` rather than the product card's `cover` because these images are usually
 * background-removed and cropping cuts the sleeves off; the pinned background
 * keeps a transparent PNG from rendering as a black silhouette on LINE's dark
 * chat surface.
 */
function wardrobeBubble(item: LineWardrobeItem): object {
  return {
    type: "bubble",
    size: "kilo",
    hero: {
      type: "image",
      url: item.imageUrl,
      size: "full",
      aspectRatio: "1:1",
      aspectMode: "fit",
      backgroundColor: CARD_COLOR.surface,
    },
    body: {
      type: "box",
      layout: "vertical",
      paddingAll: "16px",
      contents: wardrobeInfoContents(item),
    },
    footer: {
      type: "box",
      layout: "vertical",
      spacing: "sm",
      paddingAll: "16px",
      paddingTop: "0px",
      contents: [
        primaryButton("試穿這件", {
          type: "postback",
          label: "試穿這件",
          data: wardrobeTryonPostbackData(item.id),
          // Not clamped, unlike a product's: `garmentNoun` bounds the word to
          // a fixed set of short labels, far from displayText's 300-character cap.
          displayText: `試穿「你的${garmentNoun(item.categoryLabel)}」`,
        }),
      ],
    },
    styles: {
      body: { backgroundColor: CARD_COLOR.surface },
      footer: { backgroundColor: CARD_COLOR.surface },
    },
  };
}

const bubble = (card: LineCard): object =>
  card.kind === "product" ? productBubble(card.item) : wardrobeBubble(card.item);

/**
 * What a carousel is called when it cannot be shown — a notification, or a
 * client that will not render Flex. Named for what is in it, because "件商品"
 * is wrong for clothes the sender already owns.
 */
function carouselAltText(items: LineCard[]): string {
  const hasProduct = items.some((c) => c.kind === "product");
  const hasWardrobe = items.some((c) => c.kind === "wardrobe");

  if (hasWardrobe && !hasProduct) return `你衣櫃裡的 ${items.length} 件`;
  if (hasProduct && !hasWardrobe) return `為你找到 ${items.length} 件商品`;
  return `為你找到 ${items.length} 件`;
}

function carouselMessage(items: LineCard[]): object {
  return {
    type: "flex",
    altText: carouselAltText(items),
    contents: { type: "carousel", contents: items.map(bubble) },
  };
}

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

const sectionMessages = (section: Section): object[] =>
  section.kind === "text"
    ? [textMessage(section.lines)]
    : chunk(section.items, MAX_BUBBLES).map(carouselMessage);

/**
 * All the prose, then all the cards — collapsed to sections rather than straight
 * to messages, so `sectionMessages` stays the one route to a message and the
 * chunk size, the altText and the character cap cannot drift.
 */
function foldSections(sections: Section[]): Section[] {
  const lines = sections.flatMap((s) => s.kind === "text" ? s.lines : []);
  const items = sections.flatMap((s) => s.kind === "cards" ? s.items : []);

  const folded: Section[] = [];
  if (lines.length > 0) folded.push({ kind: "text", lines });
  if (items.length > 0) folded.push({ kind: "cards", items });
  return folded;
}

/** Only when the answer recommended something: the chips narrow a set of products. */
function answerChips(blocks: ContentBlock[]): object[] {
  if (!blocks.some((b) => b.type === "product")) return [];
  return [
    messageChip("便宜一點的", "有便宜一點的嗎"),
    messageChip("換個風格", "換個風格看看"),
    messageChip("幫我配整套", "幫我配一整套穿搭"),
  ];
}

/**
 * When the interleaving fits it is kept; when it does not, everything folds into
 * one block of prose followed by the carousels. Only the fold can drop anything,
 * and only once the carousels alone outrun `MAX_LINE_MESSAGES`.
 *
 * The chips are attached last, after any fold and its slice: a message the slice
 * drops must not take its chip's would-be home down with it.
 */
export function renderAnswer(blocks: ContentBlock[]): object[] {
  const sections = toSections(blocks);

  // Unreachable today (`runChatAgent` guarantees at least one block), but LINE
  // rejects an empty send outright, and a 400 is a worse way to learn that a
  // future change broke the guarantee than a generic apology is.
  if (sections.length === 0) return [chatErrorMessage("unknown")];

  const detailed = sections.flatMap(sectionMessages);
  const messages = detailed.length <= MAX_LINE_MESSAGES
    ? detailed
    : foldSections(sections).flatMap(sectionMessages).slice(0, MAX_LINE_MESSAGES);

  return dressLast(messages, answerChips(blocks));
}
