-- Add an optional human-readable `slug` to store_profiles so a store can be
-- resolved by a clean handle (e.g. /store/nike-xinyi) in addition to its
-- canonical uuid. The uuid id remains the primary key and stays fully usable;
-- slug is purely an alternate lookup key for deep links and shareable URLs.
--
-- Note: the store-owner dashboard lives under /dashboard/..., so /store/<slug>
-- is the sole occupant of the /store/ namespace and cannot shadow any app
-- route. No reserved-word guard is needed here — only format validation.

ALTER TABLE "public"."store_profiles"
  ADD COLUMN IF NOT EXISTS "slug" "text";

-- URL-safe slugs: lowercase alphanumerics separated by single hyphens, 2-63 chars.
ALTER TABLE "public"."store_profiles"
  ADD CONSTRAINT "store_profiles_slug_check" CHECK (
    "slug" IS NULL OR (
      "slug" ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
      AND char_length("slug") BETWEEN 2 AND 63
    )
  );

-- Unique only across non-null slugs (a unique index permits multiple NULLs),
-- so existing rows without a slug are unaffected.
CREATE UNIQUE INDEX IF NOT EXISTS "store_profiles_slug_key"
  ON "public"."store_profiles" ("slug");
