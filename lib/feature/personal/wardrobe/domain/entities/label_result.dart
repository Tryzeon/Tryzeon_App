import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:tryzeon/feature/common/product_attributes/domain/entities/wardrobe_category.dart';

part 'label_result.freezed.dart';

@freezed
sealed class LabelResult with _$LabelResult {
  const factory LabelResult({
    @Default([]) final List<String> tags,
    final WardrobeCategory? category,
  }) = _LabelResult;
}
