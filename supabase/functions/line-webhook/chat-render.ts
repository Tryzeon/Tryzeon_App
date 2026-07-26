/**
 * Renders an answer as LINE messages.
 *
 * The core hands back an ordered list of blocks — text and products, in the
 * sequence the model composed them. LINE has no equivalent of that sequence: it
 * has messages, and a bubble carousel is one message. So consecutive products
 * collapse into one carousel and each text block stays its own message, which
 * preserves the ordering the model meant ("上身…" then the top, "下身…" then the
 * bottom) for as long as it fits in a single send.
 */
import type { ContentBlock } from "../_shared/chat/index.ts";
import type { LineProduct } from "./chat-hydrate.ts";
import { chatErrorMessage } from "./messages.ts";

/** Messages one reply/push may carry. */
const MAX_LINE_MESSAGES = 5;
/** Bubbles one carousel may carry. A search returns at most 10, so this is slack. */
const MAX_BUBBLES = 12;
/** Characters one text message may carry. */
const MAX_TEXT_CHARS = 5000;

type Section =
  | { kind: "text"; lines: string[] }
  | { kind: "cards"; items: LineProduct[] };

/**
 * Groups the answer into alternating runs of prose and products, preserving
 * order. A run, not a block, is the unit: three products in a row are one
 * carousel, and two adjacent text blocks are one message rather than two.
 */
function toSections(blocks: ContentBlock[]): Section[] {
  const sections: Section[] = [];

  for (const block of blocks) {
    const last = sections.at(-1);
    if (block.type === "text") {
      if (last?.kind === "text") last.lines.push(block.text);
      else sections.push({ kind: "text", lines: [block.text] });
    } else if (block.type === "product") {
      const item = block.item as LineProduct;
      if (last?.kind === "cards") last.items.push(item);
      else sections.push({ kind: "cards", items: [item] });
    }
  }
  return sections;
}

function textMessage(lines: string[]): object {
  return { type: "text", text: lines.join("\n").slice(0, MAX_TEXT_CHARS) };
}

function priceText(price: number): string {
  return `NT$ ${Math.round(price).toLocaleString("en-US")}`;
}

function bubble(product: LineProduct): object {
  const body: object[] = [
    { type: "text", text: product.name, weight: "bold", size: "sm", wrap: true, maxLines: 2 },
    { type: "text", text: priceText(product.price), size: "sm", color: "#333333" },
  ];
  if (product.storeName) {
    body.push({ type: "text", text: product.storeName, size: "xs", color: "#999999", wrap: true });
  }

  // A LINE uri action only accepts an absolute http(s) link, and one it rejects
  // fails the whole send rather than the one button — so a link that cannot be
  // an action simply isn't offered as one, and the card falls back to being
  // display-only.
  const linkable = product.purchaseUrl?.startsWith("http") ? product.purchaseUrl : null;

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
    body: { type: "box", layout: "vertical", spacing: "xs", contents: body },
    ...(linkable
      ? {
        footer: {
          type: "box",
          layout: "vertical",
          contents: [{
            type: "button",
            style: "primary",
            height: "sm",
            action: { type: "uri", label: "前往購買", uri: linkable },
          }],
        },
      }
      : {}),
  };
}

function carouselMessage(items: LineProduct[]): object {
  return {
    type: "flex",
    altText: `為你找到 ${items.length} 件商品`,
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
 */
export function renderAnswer(blocks: ContentBlock[]): object[] {
  const sections = toSections(blocks);

  // `runChatAgent` guarantees at least one block, so this is unreachable today —
  // but LINE rejects an empty send outright, and a 400 is a worse way to learn
  // that a future change broke the guarantee than a generic apology is.
  if (sections.length === 0) return [chatErrorMessage("unknown")];

  const detailed = sections.flatMap(sectionMessages);
  if (detailed.length <= MAX_LINE_MESSAGES) return detailed;

  return foldSections(sections).flatMap(sectionMessages).slice(0, MAX_LINE_MESSAGES);
}
