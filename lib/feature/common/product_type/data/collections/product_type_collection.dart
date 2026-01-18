import 'package:isar/isar.dart';

part 'product_type_collection.g.dart';

@collection
class ProductTypeCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String typeId;

  late String name;
}
