import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_order_contact.freezed.dart';

/// A store's direct-message ordering channel (for stores without an online shop).
enum OrderContactType {
  line('line', 'LINE'),
  facebook('facebook', 'Facebook'),
  instagram('instagram', 'Instagram');

  const OrderContactType(this.code, this.label);

  final String code;
  final String label;

  static OrderContactType? fromCode(final String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

@freezed
sealed class StoreOrderContact with _$StoreOrderContact {
  const factory StoreOrderContact({
    required final OrderContactType type,
    required final String value,
  }) = _StoreOrderContact;
}
