import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/mappers/product_status_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:typed_result/typed_result.dart';

/// Lists or unlists [product], reporting the outcome.
///
/// No confirmation dialog: the write is reversible from the snack bar it
/// leaves behind, and a prompt on a reversible action only trains the owner to
/// dismiss the one on delete, which is not reversible.
///
/// Shared by the card's action sheet and the edit page so both get the same
/// undo. Neither switches tabs afterwards — an owner unlisting several
/// sold-out items in one pass would lose that flow, and the card leaving the
/// grid already says where it went.
Future<void> toggleProductStatus(
  final BuildContext context,
  final WidgetRef ref,
  final Product product,
) => _setStatus(context, ref, product, product.status.toggled);

Future<void> _setStatus(
  final BuildContext context,
  final WidgetRef ref,
  final Product product,
  final ProductStatus target, {
  final bool undoable = true,
}) async {
  final result = await ref
      .read(productEditProvider.notifier)
      .setStatus(product: product, status: target);

  if (!context.mounted) return;

  if (result.isFailure) {
    TopNotification.show(
      context,
      message: result.getError()!.displayMessage(context),
    );
    return;
  }

  AppSnackBar.show(
    context,
    message: target.arrivedMessage,
    actionLabel: undoable ? '復原' : null,
    onAction: undoable
        ? () => _setStatus(context, ref, product, product.status, undoable: false)
        : null,
  );
}
