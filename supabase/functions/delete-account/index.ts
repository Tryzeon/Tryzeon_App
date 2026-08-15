import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { json } from "../_shared/http.ts";
import { USER_AVATARS_BUCKET, WARDROBE_IMAGES_BUCKET } from "../_shared/storage.ts";
import { getAdminClient, getAuthenticatedUserClient } from "../_shared/supabase.ts";

// --- Error Handling ---
class AppError extends Error {
  constructor(public override message: string, public statusCode: number = 500) {
    super(message);
    this.name = "AppError";
  }
}

// --- Storage Cleanup Service ---
class StorageCleanupService {
  constructor(private supabase: SupabaseClient) { }

  private async listFilesRecursively(bucket: string, path: string): Promise<string[]> {
    let allFiles: string[] = [];
    let stack: string[] = [path];

    while (stack.length > 0) {
      const currentPath = stack.pop()!;
      // List contents of current directory
      const { data: contents, error } = await this.supabase.storage
        .from(bucket)
        .list(currentPath);

      if (error) {
        console.warn(`Error listing files in ${bucket}/${currentPath}:`, error);
        continue;
      }

      if (!contents || contents.length === 0) continue;

      for (const item of contents) {
        // Construct full path relative to bucket root.
        // If currentPath is empty, item.name is the path.
        // Otherwise join with slash.
        const itemPath = currentPath ? `${currentPath}/${item.name}` : item.name;

        if (item.id === null) {
          // If 'id' is null, it's a folder in Supabase Storage.
          // Add to stack to explore deeper.
          stack.push(itemPath);
        } else {
          // It's a file, add to list for deletion
          allFiles.push(itemPath);
        }
      }
    }
    return allFiles;
  }

  private async deleteFiles(bucket: string, filePaths: string[]) {
    if (filePaths.length === 0) return;

    // Supabase can delete multiple files at once.
    // Batching (e.g. 50 at a time) is good practice if needed.
    const CHUNK_SIZE = 50;
    for (let i = 0; i < filePaths.length; i += CHUNK_SIZE) {
      const chunk = filePaths.slice(i, i + CHUNK_SIZE);
      const { error } = await this.supabase.storage
        .from(bucket)
        .remove(chunk);

      if (error) {
        console.warn(`Failed to delete chunk from ${bucket}:`, error);
      }
    }
  }

  /**
   * Runs on the caller's own client. Both buckets are laid out `userId/…` and
   * their policies key on `(storage.foldername(name))[1] = auth.uid()`, so the
   * account being deleted already has list and delete rights over exactly the
   * objects this sweeps — and RLS, rather than a `startsWith` check nobody
   * would notice going missing, is what keeps it off everyone else's.
   *
   * Only the user-scoped Supabase buckets. Store logos and product images used
   * to be swept from here too, but they live in R2 under `stores/` now (see
   * `_shared/storage.ts`, written by `store-images`), so that branch was naming
   * buckets nothing writes to — and swallowing the resulting error. Deleting the
   * auth user orphans those R2 keys; nothing collects them today.
   */
  async cleanupUserStorage(userId: string): Promise<void> {
    const userBuckets = [USER_AVATARS_BUCKET, WARDROBE_IMAGES_BUCKET];
    await Promise.all(
      userBuckets.map(async (bucket) => {
        try {
          // List recursively starting from userId/ since these buckets use userId as root folder
          const files = await this.listFilesRecursively(bucket, userId);
          if (files.length > 0) {
            console.log(`Deleting ${files.length} files from ${bucket}/${userId}`);
            await this.deleteFiles(bucket, files);
          }
        } catch (error) {
          console.warn(`Cleanup error in ${bucket}:`, error);
        }
      })
    );
  }
}

// --- Main Handler ---
Deno.serve(async (req) => {
  try {
    // 1. Authentication
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    // 2. Clean up user storage files, on the caller's own client.
    const storageService = new StorageCleanupService(userClient!);
    await storageService.cleanupUserStorage(user!.id);

    // 3. Delete auth user (triggers cascade delete for all DB records). The one
    //    step that genuinely needs the service role — and it comes last, so the
    //    key is held only after every RLS-bounded operation is done.
    const { error: deleteAuthError } = await getAdminClient().auth.admin.deleteUser(user!.id);
    if (deleteAuthError) {
      console.error("Failed to delete auth user:", deleteAuthError);
      throw new AppError("Failed to delete authentication account", 500);
    }

    // 4. Success response
    return json({ message: "Account deleted successfully" });
  } catch (err) {
    console.error(err);

    const status = err instanceof AppError ? err.statusCode : 500;
    const message = err instanceof AppError ? err.message : "Internal Server Error";

    return json({ message }, status);
  }
});
