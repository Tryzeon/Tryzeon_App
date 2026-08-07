/**
 * Renders an answer as LINE messages.
 *
 * The core hands back an ordered list of blocks — text, shop products and the
 * sender's own wardrobe items, in the sequence the model composed them. LINE
 * has no equivalent of that sequence: it has messages, and a bubble carousel is
 * one message. So consecutive cards collapse into one carousel and each text
 * block stays its own message, which preserves the ordering the model meant
 * ("上身…" then the top, "下身…" then the bottom) for as long as it fits in a
 * single send.
 */
import type { ContentBlock } from "../_shared/chat/index.ts";
import {
  clampProductName,
  type LineProduct,
  productInfoContents,
  purchaseAction,
} from "./product-card.ts";
import { type LineWardrobeItem, wardrobeInfoContents } from "./wardrobe-card.ts";
import { CARD_COLOR, primaryButton, secondaryButton } from "./card-kit.ts";
import { chatErrorMessage } from "./messages.ts";
import { tryonPostbackData } from "./postback.ts";
import { dressLast, messageChip } from "./quick-reply.ts";

/** Messages one reply/push may carry. */
const MAX_LINE_MESSAGES = 5;
/** Bubbles one carousel may carry. A search returns at most 10, so this is slack. */
const MAX_BUBBLES = 12;
/** Characters one text message may carry. */
const MAX_TEXT_CHARS = 5000;

/**
 * One card in a carousel. A union rather than two section kinds: the two sit
 * side by side in one carousel, so everything between here and the send —
 * chunking, folding, the message cap — is written against cards, not tables.
 */
type LineCard =
  | { kind: "product"; item: LineProduct }
  | { kind: "wardrobe"; item: LineWardrobeItem };

type Section =
  | { kind: "text"; lines: string[] }
  | { kind: "cards"; items: LineCard[] };

/**
 * Groups the answer into alternating runs of prose and products, preserving
 * order. A run, not a block, is the unit: three products in a row are one
 * carousel, and two adjacent text blocks are one message rather than two.
 */
function toSections(blocks: ContentBlock[]): Section[] {
  const sections: Section[] = [];

  const pushCard = (card: LineCard) => {
    const last = sections.at(-1);
    if (last?.kind === "cards") last.items.push(card);
    else sections.push({ kind: "cards", items: [card] });
  };

  for (const block of blocks) {
    if (block.type === "text") {
      const last = sections.at(-1);
      if (last?.kind === "text") last.lines.push(block.text);
      else sections.push({ kind: "text", lines: [block.text] });
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

/**
 * One product as a card. The try-on is the primary action and is always
 * offered; buying is a link the product may or may not have, so it sits
 * beneath in the quieter style.
 */
function productBubble(product: LineProduct): object {
  const purchase = purchaseAction(product);
  const buttons: object[] = [
    primaryButton("試穿這件", {
      type: "postback",
      label: "試穿這件",
      data: tryonPostbackData(product.id),
      // Without this the tap leaves no trace, and the bot appears to start
      // talking for no reason. Clamped: `displayText` fails the whole send
      // past 300 characters, and a product name has no length constraint.
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
 * One wardrobe item as a card.
 *
 * No footer: this channel cannot try one on yet. `contain` rather than the
 * product card's `cover` because these images are usually background-removed
 * (`AnalyzeWardrobeImage.removeBackground`) and cropping cuts the sleeves off;
 * the pinned background is what keeps a transparent PNG from rendering as a
 * black silhouette on LINE's dark chat surface.
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
      aspectMode: "contain",
      backgroundColor: CARD_COLOR.surface,
    },
    body: {
      type: "box",
      layout: "vertical",
      paddingAll: "16px",
      contents: wardrobeInfoContents(item),
    },
    styles: {
      body: { backgroundColor: CARD_COLOR.surface },
    },
  };
}

const bubble = (card: LineCard): object =>
  card.kind === "product" ? productBubble(card.item) : wardrobeBubble(card.item);

/**
 * What a carousel is called when it cannot be shown — a notification, or a
 * client that will not render Flex. Named for what is in it, because "件商品"
 * is wrong for clothes the sender already owns.
 *
 * Asked per kind rather than by counting products against the total: counting
 * would make "none of them are products" mean "all of them are wardrobe", which
 * only holds while the union has exactly two arms, and would answer an empty
 * carousel with the most confident wording of the three.
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

/** A run as messages: prose is one, products are one carousel per 12. */
const sectionMessages = (section: Section): object[] =>
  section.kind === "text"
    ? [textMessage(section.lines)]
    : chunk(section.items, MAX_BUBBLES).map(carouselMessage);

/**
 * The whole answer as at most two sections: all the prose, then all the cards.
 *
 * Collapsing to sections rather than straight to messages keeps one route from
 * a section to a message — `sectionMessages` — so the chunk size, the altText
 * and the character cap are stated once and cannot drift between the two
 * layouts.
 */
function foldSections(sections: Section[]): Section[] {
  const lines = sections.flatMap((s) => s.kind === "text" ? s.lines : []);
  const items = sections.flatMap((s) => s.kind === "cards" ? s.items : []);

  const folded: Section[] = [];
  if (lines.length > 0) folded.push({ kind: "text", lines });
  if (items.length > 0) folded.push({ kind: "cards", items });
  return folded;
}

/**
 * What an answer offers next.
 *
 * Only when it recommended something: the chips narrow a set of products, so
 * they only make sense once the answer contains at least one.
 */
function answerChips(blocks: ContentBlock[]): object[] {
  if (!blocks.some((b) => b.type === "product")) return [];
  return [
    messageChip("便宜一點的", "有便宜一點的嗎"),
    messageChip("換個風格", "換個風格看看"),
    messageChip("幫我配整套", "幫我配一整套穿搭"),
  ];
}

/**
 * The answer as messages, never more than LINE accepts in one send.
 *
 * When the interleaving fits, it is kept. When it does not — an outfit with
 * four labelled parts runs to eight sections — everything folds into one block
 * of prose followed by the carousels. That loses which line introduced which
 * product, but the model names its picks in the prose and the carousels stay in
 * the same order, so the pairing survives by reading rather than by layout.
 *
 * Only the fold can drop anything, and only once the carousels alone outrun
 * `MAX_LINE_MESSAGES`: a search returns 10 products, so reaching that would take
 * several searches whose every result was recommended. The cap is stated rather
 * than assumed away because silently sending four fifths of an answer is worse
 * than a rule you can read.
 *
 * The chips are attached last, after any fold and its slice: a message the
 * slice drops must not take its chip's would-be home down with it. Which of
 * the surviving messages wears them is `dressLast`'s rule, not this one's.
 */
export function renderAnswer(blocks: ContentBlock[]): object[] {
  const sections = toSections(blocks);

  // `runChatAgent` guarantees at least one block, so this is unreachable today —
  // but LINE rejects an empty send outright, and a 400 is a worse way to learn
  // that a future change broke the guarantee than a generic apology is.
  if (sections.length === 0) return [chatErrorMessage("unknown")];

  const detailed = sections.flatMap(sectionMessages);
  const messages = detailed.length <= MAX_LINE_MESSAGES
    ? detailed
    : foldSections(sections).flatMap(sectionMessages).slice(0, MAX_LINE_MESSAGES);

  return dressLast(messages, answerChips(blocks));
}
