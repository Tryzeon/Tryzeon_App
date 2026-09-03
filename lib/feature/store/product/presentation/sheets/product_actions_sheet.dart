import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_status_ui_mapper.dart';

/// A sheet rather than a `PopupMenuButton`: the menu would arrive with M3
/// elevation, which the design system rules out.
///
/// Returns whether the owner picked the action rather than running it — the
/// work outlives this sheet, and its context is gone the moment it pops.
///
/// Editing and deleting are deliberately absent. Tapping the card already
/// opens the editor, and delete stays behind its danger zone: putting 下架 on
/// the card is meant to make the reversible action the easy one, which a
/// delete row two pixels away would undo.
class ProductActionsSheet extends StatelessWidget {
  const ProductActionsSheet({super.key, required this.product});

  final Product product;

  static Future<bool?> show(
    final BuildContext context,
    final Product product,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (final _) => ProductActionsSheet(product: product),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              product.name,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ListTile(
            leading: Icon(
              product.status == ProductStatus.active
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            title: Text(product.status.toggleLabel),
            onTap: () => context.pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
