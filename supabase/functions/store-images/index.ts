import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { deletePublicImagesFromR2, generatePresignedPutUrl } from "../_shared/r2.ts";
import { json } from "../_shared/http.ts";

const ALLOWED_MIMES = new Set(["image/jpeg", "image/png", "image/webp"]);
const MAX_BYTES = 5 * 1024 * 1024;

const MIME_TO_EXT: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

function validateContentLength(value: unknown): Response | number {
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    return json({ error: "Missing or invalid contentLength", code: "VALIDATION_ERROR" }, 400);
  }
  if (value > MAX_BYTES) {
    return json({ error: `File too large: ${value} bytes`, code: "VALIDATION_ERROR" }, 400);
  }
  return value;
}

type AdminClient = ReturnType<typeof getAdminClient>;

function logoKey(storeId: string, contentType: string): string {
  const ext = MIME_TO_EXT[contentType];
  return `stores/${storeId}/logo/${crypto.randomUUID()}.${ext}`;
}

function productKey(storeId: string, productId: string, contentType: string): string {
  const ext = MIME_TO_EXT[contentType];
  return `stores/${storeId}/products/${productId}/${crypto.randomUUID()}.${ext}`;
}

function isUuid(s: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
}

async function assertStoreOwner(
  adminClient: AdminClient,
  userId: string,
  storeId: string,
): Promise<Response | null> {
  const { data, error } = await adminClient
    .from("store_profiles")
    .select("owner_id")
    .eq("id", storeId)
    .single();
  if (error || !data) {
    return json({ error: "Store not found", code: "NOT_FOUND" }, 404);
  }
  if ((data as { owner_id: string }).owner_id !== userId) {
    return json({ error: "Forbidden", code: "FORBIDDEN" }, 403);
  }
  return null;
}

Deno.serve(async (req) => {
  const { user, errorResponse } = await getAuthenticatedUserClient(req);
  if (errorResponse) return errorResponse;
  const adminClient = getAdminClient();

  const url = new URL(req.url);
  const sub = url.pathname.replace(/^.*\/store-images\/?/, "").replace(/\/$/, "");

  try {
    if (req.method === "POST" && sub === "presign-logo") {
      return await handlePresignLogo(req, adminClient, user!.id);
    }
    if (req.method === "POST" && sub === "presign-products") {
      return await handlePresignProducts(req, adminClient, user!.id);
    }
    if (req.method === "POST" && sub === "delete") {
      return await handleDelete(req, adminClient, user!.id);
    }
    return json({ error: "Not found", code: "NOT_FOUND" }, 404);
  } catch (err) {
    console.error("store-images error", err);
    return json({ error: "Internal server error", code: "INTERNAL" }, 500);
  }
});

async function handlePresignLogo(
  req: Request,
  adminClient: AdminClient,
  userId: string,
): Promise<Response> {
  const body = await req.json().catch(() => null);
  const storeId = body?.storeId;
  const contentType = body?.contentType;

  if (typeof storeId !== "string" || !storeId) {
    return json({ error: "Missing storeId", code: "VALIDATION_ERROR" }, 400);
  }
  if (typeof contentType !== "string" || !ALLOWED_MIMES.has(contentType)) {
    return json({ error: `Invalid contentType: ${contentType}`, code: "VALIDATION_ERROR" }, 400);
  }

  const contentLength = validateContentLength(body?.contentLength);
  if (contentLength instanceof Response) return contentLength;

  const ownerErr = await assertStoreOwner(adminClient, userId, storeId);
  if (ownerErr) return ownerErr;

  const key = logoKey(storeId, contentType);
  const uploadUrl = await generatePresignedPutUrl({ key, contentType, contentLength });
  return json({ key, uploadUrl });
}

async function handlePresignProducts(
  req: Request,
  adminClient: AdminClient,
  userId: string,
): Promise<Response> {
  const body = await req.json().catch(() => null);
  const storeId = body?.storeId;
  const productId = body?.productId;
  const files = body?.files;

  if (typeof storeId !== "string" || !storeId) {
    return json({ error: "Missing storeId", code: "VALIDATION_ERROR" }, 400);
  }
  if (typeof productId !== "string" || !isUuid(productId)) {
    return json({ error: "Missing or invalid productId", code: "VALIDATION_ERROR" }, 400);
  }
  if (!Array.isArray(files) || files.length === 0) {
    return json({ error: "Missing files", code: "VALIDATION_ERROR" }, 400);
  }
  for (const f of files) {
    if (typeof f?.contentType !== "string" || !ALLOWED_MIMES.has(f.contentType)) {
      return json({ error: `Invalid contentType: ${f?.contentType}`, code: "VALIDATION_ERROR" }, 400);
    }
    const lenOrErr = validateContentLength(f?.contentLength);
    if (lenOrErr instanceof Response) return lenOrErr;
  }

  const ownerErr = await assertStoreOwner(adminClient, userId, storeId);
  if (ownerErr) return ownerErr;

  const items = await Promise.all(
    (files as Array<{ contentType: string; contentLength: number }>).map(async (f) => {
      const key = productKey(storeId, productId, f.contentType);
      const uploadUrl = await generatePresignedPutUrl({
        key,
        contentType: f.contentType,
        contentLength: f.contentLength,
      });
      return { key, uploadUrl };
    }),
  );
  return json({ items });
}

async function handleDelete(
  req: Request,
  adminClient: AdminClient,
  userId: string,
): Promise<Response> {
  const body = await req.json().catch(() => null);
  const storeId = body?.storeId;
  const keys = body?.keys;

  if (typeof storeId !== "string" || !storeId) {
    return json({ error: "Missing storeId", code: "VALIDATION_ERROR" }, 400);
  }
  if (!Array.isArray(keys) || keys.length === 0) {
    return json({ error: "Missing keys", code: "VALIDATION_ERROR" }, 400);
  }
  
  // Enforce that every key lives under this store's namespace so the caller
  // cannot delete another store's objects even if assertStoreOwner passes.
  const prefix = `stores/${storeId}/`;
  for (const k of keys) {
    if (typeof k !== "string" || !k.startsWith(prefix)) {
      return json({ error: "Invalid key for store", code: "VALIDATION_ERROR" }, 400);
    }
  }

  const ownerErr = await assertStoreOwner(adminClient, userId, storeId);
  if (ownerErr) return ownerErr;

  await deletePublicImagesFromR2(keys as string[]);
  return json({ deleted: keys.length });
}
