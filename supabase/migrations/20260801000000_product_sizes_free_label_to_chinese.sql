-- The one-size literal changes from `F` to `均碼`, matching
-- StandardSizeLabel.free.display
-- (lib/feature/common/product_size/domain/entities/standard_size_label.dart)。
--
-- Alias folding only happens on the voice-input write path; the client matches
-- literals and converts nothing. So unless the existing `F` values are changed
-- too, an older product opens with them treated as custom sizes: they no longer
-- map to the `均碼` chip, and they sort into the custom block instead of last.
UPDATE "public"."product_sizes"
SET "name" = '均碼'
WHERE btrim("name") ILIKE 'f';
