import 'package:equatable/equatable.dart';

enum SortField { name, price, createdAt, updatedAt, tryonCount, purchaseClickCount }

class SortCondition extends Equatable {
  const SortCondition({required this.field, required this.ascending});

  final SortField field;
  final bool ascending;

  static const defaultSort = SortCondition(field: SortField.createdAt, ascending: false);

  @override
  List<Object?> get props => [field, ascending];
}
