-- Replace the exact integer `age` on user_profiles with a coarse `age_range`
-- bucket. Exact age lowered onboarding conversion and is more granular than the
-- internal cohort analysis needs; buckets are the analysis unit and feel less
-- invasive to fill in. Stored as text (matching the gender / style_preferences
-- text convention) so the app's AgeRange enum maps to it directly.

ALTER TABLE "public"."user_profiles"
  ADD COLUMN IF NOT EXISTS "age_range" "text";

UPDATE "public"."user_profiles"
SET "age_range" = CASE
  WHEN "age" IS NULL THEN NULL
  WHEN "age" <= 12 THEN 'under_12'
  WHEN "age" BETWEEN 13 AND 17 THEN '13_17'
  WHEN "age" BETWEEN 18 AND 24 THEN '18_24'
  WHEN "age" BETWEEN 25 AND 34 THEN '25_34'
  WHEN "age" BETWEEN 35 AND 54 THEN '35_54'
  ELSE '55_plus'
END
WHERE "age" IS NOT NULL;

-- Guard the bucket vocabulary so analytics queries stay clean.
ALTER TABLE "public"."user_profiles"
  ADD CONSTRAINT "user_profiles_age_range_check"
  CHECK (
    "age_range" IS NULL OR "age_range" IN (
      'under_12', '13_17', '18_24', '25_34', '35_54', '55_plus'
    )
  );

-- Exact age is no longer collected or read anywhere.
ALTER TABLE "public"."user_profiles"
  DROP COLUMN IF EXISTS "age";
