import 'package:equatable/equatable.dart';

class ProductType extends Equatable {
  const ProductType({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}
