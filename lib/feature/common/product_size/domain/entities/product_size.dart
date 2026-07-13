import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';

part 'product_size.freezed.dart';

@freezed
sealed class ProductSize with _$ProductSize {
  const factory ProductSize({
    required final String id,
    required final String productId,
    required final String name,
    final Measurements? measurements,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _ProductSize;
}
