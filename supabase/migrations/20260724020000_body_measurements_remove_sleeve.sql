-- Remove the retired `sleeve` body measurement from stored shopper profiles.
--
-- `sleeve` (arm/sleeve length) was dropped from the body-measurement field set:
-- it is a garment property, ambiguous to self-measure, and not needed for the
-- current fit model. `user_profiles.measurements` is jsonb and sparse, so this
-- is a data cleanup only — no schema change. New client code already ignores
-- unknown keys; this strips the orphan so the stored shape matches the model.

UPDATE "public"."user_profiles"
SET "measurements" = "measurements" - 'sleeve'
WHERE "measurements" ? 'sleeve';
