import { getOrCreateUserId as defaultGetOrCreateUserId } from "../_shared/line-user.ts";
import {
  classifyTryonError,
  runTryonJob,
  supabaseQuota,
} from "../_shared/tryon/index.ts";
import type { GarmentInput } from "../_shared/tryon/types.ts";
import { uint8ToBase64 } from "../_shared/image-utils.ts";
import { getAvatarPath as defaultGetAvatarPath } from "../_shared/user-profile.ts";
import { fetchProductInfo } from "./product-card.ts";
import { fetchWardrobeItemInfo } from "./wardrobe-card.ts";
import { describeGarment as defaultDescribeGarment } from "./garment-analysis.ts";
import {
  onboardingMessage,
  processingMessage,
  productProcessingMessage,
  productResultMessage,
  productTryonErrorMessage,
  productUnavailableMessage,
  resultMessage,
  tryonErrorMessage,
  type TryonJobErrorKind,
  wardrobeProcessingMessage,
  wardrobeResultMessage,
  wardrobeTryonErrorMessage,
  wardrobeUnavailableMessage,
} from "./messages.ts";
import { LineApi } from "./line-api.ts";
import {
  type ConversationStore,
  photoNote,
  tryonNote,
  wardrobeTryonNote,
} from "./conversation.ts";
import type { DbClient } from "../_shared/supabase.ts";

export interface TryonHandlerDeps {
  admin: DbClient;
  line: LineApi;
  liffUrl: string;
  conversations: ConversationStore;
  getAvatarPath?: typeof defaultGetAvatarPath;
  getOrCreateUserId?: typeof defaultGetOrCreateUserId;
  runJob?: typeof runTryonJob;
}

interface Actor {
  userId: string;
  hasAvatar: boolean;
}

/** A first-time sender is minted an account here, so this is a write as much as a read. */
async function resolveActor(
  deps: TryonHandlerDeps,
  sourceUserId: string,
): Promise<Actor> {
  const getOrCreateUserId = deps.getOrCreateUserId ?? defaultGetOrCreateUserId;
  const getAvatarPath = deps.getAvatarPath ?? defaultGetAvatarPath;

  const userId = await getOrCreateUserId(
    deps.admin,
    { sub: sourceUserId },
    () => deps.line.getDisplayName(sourceUserId),
  );
  return {
    userId,
    hasAvatar: await getAvatarPath(deps.admin, userId) !== null,
  };
}

type TryonOutcome =
  | { ok: true; imageUrl: string }
  | { ok: false; kind: TryonJobErrorKind };

async function runTryon(
  deps: TryonHandlerDeps,
  params: { userId: string; garment: GarmentInput },
): Promise<TryonOutcome> {
  const runJob = deps.runJob ?? runTryonJob;
  try {
    // Running the job on `admin` is safe here: a LINE event carries no Supabase
    // session, the avatar is resolved by the core from the user's own profile,
    // and a garment is inline base64, a product id, or a wardrobe item id — the
    // core resolves both id forms itself, binding the wardrobe one to
    // `job.userId`, so this adapter never forwards a client-supplied path.
    const result = await runJob(
      deps.admin,
      { userId: params.userId, garments: [params.garment], mode: "image" },
      { quota: supabaseQuota(deps.admin) },
    );
    return { ok: true, imageUrl: result.imageUrl };
  } catch (err) {
    const kind = tryonFailureKind(err);
    // "unknown" means a server-side fault (bad params, RLS, storage) rather
    // than a user error — log it so it leaves a trace beyond the pushed message.
    if (kind === "unknown") {
      console.error("line-webhook try-on failed:", err);
    }
    return { ok: false, kind };
  }
}

export interface ImageTryonEvent {
  replyToken: string;
  sourceUserId: string;
  messageId: string;
}

export interface ImageTryonDeps extends TryonHandlerDeps {
  describeGarment?: typeof defaultDescribeGarment;
}

export async function handleImageTryon(
  deps: ImageTryonDeps,
  event: ImageTryonEvent,
): Promise<void> {
  const describeGarment = deps.describeGarment ?? defaultDescribeGarment;
  const { userId, hasAvatar } = await resolveActor(deps, event.sourceUserId);

  if (!hasAvatar) {
    await deps.line.reply(event.replyToken, [onboardingMessage(deps.liffUrl)]);
    return;
  }

  await deps.line.reply(event.replyToken, [processingMessage()]);

  let bytes: Uint8Array;
  try {
    bytes = await deps.line.getContent(event.messageId);
  } catch (err) {
    console.warn("line-webhook failed to download garment image:", err);
    await deps.line.push(event.sourceUserId, [tryonErrorMessage("download")]);
    return;
  }

  const base64 = uint8ToBase64(bytes);

  const described = describeGarment(userId, base64).catch((err) => {
    console.warn("line-webhook garment description failed:", err);
    return null;
  });

  const outcome = await runTryon(deps, {
    userId,
    garment: { images: [{ base64 }] },
  });

  await deps.line.push(event.sourceUserId, [
    outcome.ok ? resultMessage(outcome.imageUrl) : tryonErrorMessage(outcome.kind),
  ]);

  const description = await described;
  if (description !== null) {
    const prior = await deps.conversations.load(event.sourceUserId);
    await deps.conversations.save(event.sourceUserId, [...prior, photoNote(description)]);
  }
}

export interface ProductTryonEvent {
  replyToken: string;
  sourceUserId: string;
  productId: string;
}

export interface ProductTryonDeps extends TryonHandlerDeps {
  fetchProduct?: typeof fetchProductInfo;
}

/**
 * The product is read before anything is charged: `fetchProductInfo` returns
 * null for exactly the two cases the core would later reject as validation
 * errors — the row is gone, or it has no image — so checking here turns both
 * into a sentence the user understands at no quota cost.
 */
export async function handleProductTryon(
  deps: ProductTryonDeps,
  event: ProductTryonEvent,
): Promise<void> {
  const fetchProduct = deps.fetchProduct ?? fetchProductInfo;
  const { userId, hasAvatar } = await resolveActor(deps, event.sourceUserId);

  if (!hasAvatar) {
    await deps.line.reply(event.replyToken, [onboardingMessage(deps.liffUrl)]);
    return;
  }

  const product = await fetchProduct(deps.admin, event.productId);
  if (!product) {
    await deps.line.reply(event.replyToken, [productUnavailableMessage(deps.liffUrl)]);
    return;
  }

  await deps.line.reply(event.replyToken, [productProcessingMessage(product.name)]);

  const outcome = await runTryon(deps, {
    userId,
    garment: { productId: product.id },
  });

  await deps.line.push(event.sourceUserId, [
    outcome.ok
      ? productResultMessage(outcome.imageUrl, product)
      : productTryonErrorMessage(outcome.kind, product, deps.liffUrl),
  ]);

  if (outcome.ok) {
    const prior = await deps.conversations.load(event.sourceUserId);
    await deps.conversations.save(event.sourceUserId, [...prior, tryonNote(product)]);
  }
}

export interface WardrobeTryonEvent {
  replyToken: string;
  sourceUserId: string;
  wardrobeItemId: string;
}

export interface WardrobeTryonDeps extends TryonHandlerDeps {
  fetchItem?: typeof fetchWardrobeItemInfo;
}

/**
 * The item is read before anything is charged: an item deleted since the card
 * was sent becomes a sentence the user understands and costs them no quota.
 *
 * The garment goes in as `{ wardrobeItemId }` and never as a path. This adapter
 * holds the admin client, so a path it chose would be a path with nothing
 * checking whose it was; the core resolves the id against `job.userId` instead.
 */
export async function handleWardrobeTryon(
  deps: WardrobeTryonDeps,
  event: WardrobeTryonEvent,
): Promise<void> {
  const fetchItem = deps.fetchItem ?? fetchWardrobeItemInfo;
  const { userId, hasAvatar } = await resolveActor(deps, event.sourceUserId);

  if (!hasAvatar) {
    await deps.line.reply(event.replyToken, [onboardingMessage(deps.liffUrl)]);
    return;
  }

  const item = await fetchItem(deps.admin, userId, event.wardrobeItemId);
  if (!item) {
    await deps.line.reply(event.replyToken, [wardrobeUnavailableMessage()]);
    return;
  }

  await deps.line.reply(event.replyToken, [
    wardrobeProcessingMessage(item.categoryLabel),
  ]);

  const outcome = await runTryon(deps, {
    userId,
    garment: { wardrobeItemId: item.id },
  });

  await deps.line.push(event.sourceUserId, [
    outcome.ok
      ? wardrobeResultMessage(outcome.imageUrl, item)
      : wardrobeTryonErrorMessage(outcome.kind, item),
  ]);

  if (outcome.ok) {
    const prior = await deps.conversations.load(event.sourceUserId);
    await deps.conversations.save(event.sourceUserId, [
      ...prior,
      wardrobeTryonNote(item),
    ]);
  }
}

/**
 * A validation error is not user-actionable here — this adapter builds its own
 * params, and each kind of ref is checked for existence before any job starts —
 * so it is reported as an unknown fault.
 */
function tryonFailureKind(err: unknown): TryonJobErrorKind {
  const info = classifyTryonError(err);
  if (info === null) return "unknown";
  switch (info.kind) {
    case "quota":
      return "quota";
    case "generation":
      return "generation";
    case "busy":
      return "busy";
    case "validation":
      return "unknown";
    case "missingAvatar":
      return "unknown";
  }
}
