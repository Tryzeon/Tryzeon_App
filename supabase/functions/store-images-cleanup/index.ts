import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient, CONFIG } from "../_shared/supabase.ts";
import {
  deletePublicImagesFromR2,
  listPublicImagesFromR2,
  R2ObjectInfo,
} from "../_shared/r2.ts";
import { json } from "../_shared/http.ts";

const DEFAULT_GRACE_HOURS = 24;
const DEFAULT_MAX_DELETE = 500;
const DELETE_BATCH_SIZE = 1000;
const SAMPLE_SIZE = 20;

interface SweepBody {
  dryRun?: boolean;
  graceHours?: number;
  maxDelete?: number;
}

async function collectReferencedKeys(): Promise<Set<string>> {
  const admin = getAdminClient();
  const referenced = new Set<string>();

  const { data: products, error: prodErr } = await admin
    .from("products")
    .select("image_paths");
  if (prodErr) throw new Error(`products query failed: ${prodErr.message}`);
  for (const row of products ?? []) {
    const paths = (row as { image_paths: unknown }).image_paths;
    if (Array.isArray(paths)) {
      for (const p of paths) if (typeof p === "string") referenced.add(p);
    }
  }

  const { data: stores, error: storeErr } = await admin
    .from("store_profiles")
    .select("logo_path")
    .not("logo_path", "is", null);
  if (storeErr) throw new Error(`store_profiles query failed: ${storeErr.message}`);
  for (const row of stores ?? []) {
    const logo = (row as { logo_path: string | null }).logo_path;
    if (typeof logo === "string" && logo.length > 0) referenced.add(logo);
  }

  return referenced;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed", code: "METHOD_NOT_ALLOWED" }, 405);
  }

  const body: SweepBody = await req.json().catch(() => ({}));
  const dryRun = body.dryRun ?? true;
  const graceHours = body.graceHours ?? DEFAULT_GRACE_HOURS;
  const maxDelete = body.maxDelete ?? DEFAULT_MAX_DELETE;
  const cutoff = new Date(Date.now() - graceHours * 3600 * 1000);

  try {
    const referenced = await collectReferencedKeys();
    const listed = await listPublicImagesFromR2({ prefix: "stores/" });

    const orphans: R2ObjectInfo[] = [];
    let skippedInGrace = 0;
    for (const obj of listed) {
      if (referenced.has(obj.key)) continue;
      if (obj.lastModified > cutoff) {
        skippedInGrace++;
        continue;
      }
      orphans.push(obj);
    }

    const aborted = orphans.length > maxDelete;
    const toDelete = aborted ? [] : orphans;

    let deletedCount = 0;
    if (!dryRun && !aborted && toDelete.length > 0) {
      for (let i = 0; i < toDelete.length; i += DELETE_BATCH_SIZE) {
        const batch = toDelete.slice(i, i + DELETE_BATCH_SIZE).map((o) => o.key);
        await deletePublicImagesFromR2(batch);
        deletedCount += batch.length;
      }
    }

    return json({
      dryRun,
      graceHours,
      maxDelete,
      cutoff: cutoff.toISOString(),
      listedCount: listed.length,
      referencedCount: referenced.size,
      orphanCount: orphans.length,
      skippedInGrace,
      deletedCount,
      aborted,
      abortReason: aborted ? `orphanCount (${orphans.length}) > maxDelete (${maxDelete})` : undefined,
      sampleOrphans: orphans.slice(0, SAMPLE_SIZE).map((o) => ({
        key: o.key,
        lastModified: o.lastModified.toISOString(),
      })),
    });
  } catch (err) {
    console.error("store-images-cleanup error", err);
    return json(
      { error: "Internal server error", code: "INTERNAL", message: (err as Error).message },
      500,
    );
  }
});
