import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/measurements/data/collections/measurements_embedded.dart';

part 'product_size_embedded.g.dart';

@embedded
class ProductSizeEmbedded {
  late String id;
  late String productId;
  late String name;

  MeasurementsEmbedded? measurements;
  late DateTime createdAt;
  late DateTime updatedAt;
}
