-- 單一尺寸的字面值由 `F` 改為 `均碼`，對齊 StandardSizeLabel.free.display
-- (lib/feature/common/product_size/domain/entities/standard_size_label.dart)。
--
-- 別名收斂只發生在語音辨識的寫入端；前端只比對字面值，不做轉換。所以既有的
-- `F` 若不一併改掉，舊商品打開後會被視為自訂尺碼，不再對應到「均碼」chip，
-- 排序上也會落在自訂尺碼那一段而不是最後。
UPDATE "public"."product_sizes"
SET "name" = '均碼'
WHERE btrim("name") ILIKE 'f';
