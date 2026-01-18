import 'package:equatable/equatable.dart';

class ProductType extends Equatable {
  const ProductType({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
