import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({required this.product, super.key});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Shared style for label and value — use default text color
    final textStyle = textTheme.bodyMedium;

    Widget buildInfoRow(final String label, final String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 72, child: Text(label, style: textStyle)),
            Expanded(child: Text(value, style: textStyle)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('產品資訊', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.smMd),

        if (product.material != null && product.material!.isNotEmpty)
          buildInfoRow('材質', product.material!),

        if (product.elasticity != null) buildInfoRow('彈性', product.elasticity!.label),

        if (product.thickness != null) buildInfoRow('厚薄度', product.thickness!.label),

        if (product.fit != null) buildInfoRow('版型', product.fit!.label),

        if (product.seasons != null && product.seasons!.isNotEmpty)
          buildInfoRow('季節', product.seasons!.map((final s) => s.label).join('、')),
      ],
    );
  }
}
