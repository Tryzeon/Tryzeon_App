-- Point category imagery at 360x360 WebP variants of the same artwork.
--
-- The sources are 1254px–2048px RGBA PNGs — 81.5 MB across all 24 files —
-- rendered into 56pt tiles by ProductCategoryFilter. Because the shop filters
-- categories by gender, a cold start decodes one gender's set: 11 files /
-- 40.8 MB for male, 13 files / 40.7 MB for female. Flutter's ImageCache is
-- process memory, so that decode repeats on every launch, which is the visible
-- delay on entering the shop tab.
--
-- `memCacheWidth: 180` on the widget does not save this. It caps the retained
-- bitmap, not the decode: PNG has no DCT-scaled fast path like JPEG, so all
-- 2048 rows are still inflated and un-filtered before downsampling.
--
-- The replacements are 360x360 (2x headroom over 56pt at DPR 3) and total
-- 149 KB — 561x smaller. Alpha is fully opaque in every source, so the RGBA
-- channel was dead weight and nothing is lost by re-encoding.
--
-- The `.webp` extension changes the storage key, which is load-bearing: R2
-- serves these objects with no Cache-Control, so flutter_cache_manager falls
-- back to its 7-day default (web/file_service.dart) and installed apps would
-- otherwise keep the old PNG for a week. A new key sidesteps that entirely —
-- the same reason `home_cloth_f_new.png` carries its suffix.
--
-- The PNGs stay in R2 until the WebP set is verified in production; deleting
-- them is a separate, deliberate step.

UPDATE "public"."product_categories"
SET "image_male"   = regexp_replace("image_male",   '\.png$', '.webp'),
    "image_female" = regexp_replace("image_female", '\.png$', '.webp')
WHERE "image_male" LIKE '%.png'
   OR "image_female" LIKE '%.png';
