import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_status_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:typed_result/typed_result.dart';

/// Lists or unlists [product], reporting the outcome.
///
/// No confirmation dialog: the write is reversible from the snack bar it
/// leaves behind, and a prompt on a reversible action only trains the owner to
/// dismiss the one on delete, which is not reversible.
///
/// Does not switch tabs afterwards — an owner unlisting several sold-out items
/// in one pass would lose that flow, and the card leaving the grid already
/// says where it went.
Future<void> toggleProductStatus(
  final BuildContext context,
  final Product product,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final target = product.status.toggled;

  final result = await container
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
    actionLabel: '復原',
    onAction: () => _undo(container, product),
  );
}

/// The same write in reverse. Takes no context: by the time this can run the
/// card is gone, and the product reappearing in the tab the owner is looking
/// at is the only confirmation an undo needs. A failure has no one left to
/// tell, so it goes to the log.
Future<void> _undo(
  final ProviderContainer container,
  final Product product,
) async {
  final result = await container
      .read(productEditProvider.notifier)
      .setStatus(product: product, status: product.status);

  if (result.isFailure) {
    AppLogger.error('Undoing a product status change failed', result.getError());
  }
}
