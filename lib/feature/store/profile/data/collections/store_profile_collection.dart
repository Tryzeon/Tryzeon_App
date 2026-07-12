import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';

part 'store_profile_collection.g.dart';

@collection
class StoreProfileCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String storeId;

  late String name;
  late String ownerId;
  late List<String> channels;
  String? slug;
  String? address;
  double? latitude;
  double? longitude;
  String? logoPath;
  String? logoUrl;
  List<StoreOrderContactEmbedded> orderContacts = [];

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;
}
