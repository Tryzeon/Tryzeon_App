import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { json } from "../_shared/http.ts";

// --- Configuration ---
const CONFIG = {
  SUPABASE_URL: Deno.env.get("SUPABASE_URL"),
  SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
};

// --- Error Handling ---
class AppError extends Error {
  constructor(public override message: string, public statusCode: number = 500) {
    super(message);
    this.name = "AppError";
  }
}

// --- Storage Cleanup Service ---
class StorageCleanupService {
  constructor(private supabase: any) { }

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

  async cleanupUserStorage(userId: string): Promise<void> {
    // 1. Clean User-Centric Buckets (files stored under userId/)
    const userBuckets = ["user-avatars", "wardrobe-images"];
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

    // 2. Clean Store-Centric Buckets (files stored under storeId/)
    try {
      // Fetch stores owned by user to get storeIds
      const { data: stores, error: storeError } = await this.supabase
        .from("store_profiles")
        .select("id")
        .eq("owner_id", userId);

      if (storeError) {
        console.warn("Failed to fetch user stores for cleanup:", storeError);
      } else if (stores && stores.length > 0) {
        const storeBuckets = ["store-logos", "product-images"];

        for (const store of stores) {
          const storeId = store.id;
          await Promise.all(
            storeBuckets.map(async (bucket) => {
              try {
                // Products bucket structure: storeId/products/filename (files are deeper)
                // Logos bucket structure: storeId/logo/filename
                // So we just recursively delete from storeId/
                const files = await this.listFilesRecursively(bucket, storeId);
                if (files.length > 0) {
                  console.log(`Deleting ${files.length} files from ${bucket}/${storeId}`);
                  await this.deleteFiles(bucket, files);
                }
              } catch (error) {
                console.warn(`Cleanup error in ${bucket} for store ${storeId}:`, error);
              }
            })
          );
        }
      }
    } catch (error) {
      console.warn("Error in store cleanup logic:", error);
    }
  }
}

// --- Main Handler ---
Deno.serve(async (req) => {
  try {
    // 1. Authentication
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new AppError("Missing Authorization header", 401);

    // Create user client for auth
    const userClient = createClient(
      CONFIG.SUPABASE_URL!,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) throw new AppError("Unauthorized", 401);

    // 2. Create admin client for database and storage operations
    const adminClient = createClient(
      CONFIG.SUPABASE_URL!,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY!
    );

    // 3. Clean up user storage files
    const storageService = new StorageCleanupService(adminClient);
    await storageService.cleanupUserStorage(user.id);

    // 4. Delete auth user (triggers cascade delete for all DB records)
    const { error: deleteAuthError } = await adminClient.auth.admin.deleteUser(user.id);
    if (deleteAuthError) {
      console.error("Failed to delete auth user:", deleteAuthError);
      throw new AppError("Failed to delete authentication account", 500);
    }

    // 5. Success response
    return json({ message: "Account deleted successfully" });
  } catch (err) {
    console.error(err);

    const status = err instanceof AppError ? err.statusCode : 500;
    const message = err instanceof AppError ? err.message : "Internal Server Error";

    return json({ message }, status);
  }
});
