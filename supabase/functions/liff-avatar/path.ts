/**
 * Storage path for a user's model photo. The `avatar` segment routes
 * fetchImageAsBase64 to the `user-avatars` Supabase Storage bucket.
 */
export function avatarStoragePath(userId: string, ts: number, ext: string): string {
  return `${userId}/avatar/${ts}.${ext}`;
}
