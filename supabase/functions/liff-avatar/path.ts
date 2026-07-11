/**
 * Storage path for a user's model photo in the `user-avatars` bucket. The
 * leading `userId` segment satisfies the bucket's RLS policy
 * (`(storage.foldername(name))[1] = auth.uid()`).
 */
export function avatarStoragePath(userId: string, ts: number, ext: string): string {
  return `${userId}/avatar/${ts}.${ext}`;
}
