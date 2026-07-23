import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/models/garment_measurements_model.dart';

part 'create_product_size_request.g.dart';

/// Client → Server：建立商品尺寸時使用
/// 不含 id, createdAt, updatedAt
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CreateProductSizeRequest {
  const CreateProductSizeRequest({
    required this.productId,
    required this.name,
    this.measurements,
  });

  final String productId;
  final String name;
  final GarmentMeasurementsModel? measurements;

  Map<String, dynamic> toJson() => _$CreateProductSizeRequestToJson(this);
}
