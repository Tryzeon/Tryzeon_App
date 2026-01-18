import 'package:isar/isar.dart';

part 'store_profile_collection.g.dart';

@collection
class StoreProfileCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String storeId;

  late String name;
  late String ownerId;
  String? address;
  String? logoPath;
  String? logoUrl;
}
