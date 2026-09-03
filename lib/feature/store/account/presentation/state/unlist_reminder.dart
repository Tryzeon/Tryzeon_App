import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';

typedef UnlistReminder = ({Product product, int clicks});

List<UnlistReminder> selectUnlistReminders(
  final List<Product> products,
  final Map<String, int> clicksByProductId,
) {
  final reminders = <UnlistReminder>[
    for (final product in products)
      if (product.status == ProductStatus.active &&
          (clicksByProductId[product.id] ?? 0) > 0)
        (product: product, clicks: clicksByProductId[product.id]!),
  ];

  reminders.sort((final a, final b) => b.clicks.compareTo(a.clicks));
  return reminders;
}
