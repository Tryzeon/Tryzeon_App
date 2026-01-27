import 'package:equatable/equatable.dart';

class ShopStoreInfo extends Equatable {
  const ShopStoreInfo({required this.id, this.name, this.address, this.logoUrl});

  final String id;
  final String? name;
  final String? address;
  final String? logoUrl;

  @override
  List<Object?> get props => [id, name, address, logoUrl];
}
