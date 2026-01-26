import 'package:equatable/equatable.dart';

class ShopStoreInfo extends Equatable {
  const ShopStoreInfo({required this.id, this.name, this.address});

  final String id;
  final String? name;
  final String? address;

  @override
  List<Object?> get props => [id, name, address];
}
