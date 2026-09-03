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
