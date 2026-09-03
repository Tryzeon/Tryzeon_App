import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';

export 'package:adaptive_dialog/adaptive_dialog.dart' show OkCancelResult;

/// Clean Luxe replacement for [showOkCancelAlertDialog]: neutral actions use
/// charcoal `onSurface` instead of the platform accent (lavender on Material,
/// system blue on iOS); destructive confirms keep the platform red.
Future<OkCancelResult> showAppOkCancelDialog({
  required final BuildContext context,
  final String? title,
  final String? message,
  final String? okLabel,
  final String? cancelLabel,
  final bool isDestructiveAction = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  // Destructive confirms must pass an empty TextStyle instead: a color merge
  // would override Cupertino's destructive red.
  final neutral = TextStyle(color: colorScheme.onSurface);

  final result = await showAlertDialog<OkCancelResult>(
    context: context,
    title: title,
    message: message,
    actions: [
      AlertDialogAction(
        key: OkCancelResult.cancel,
        label: cancelLabel ?? MaterialLocalizations.of(context).cancelButtonLabel,
        textStyle: neutral,
      ),
      AlertDialogAction(
        key: OkCancelResult.ok,
        label: okLabel ?? MaterialLocalizations.of(context).okButtonLabel,
        isDefaultAction: !isDestructiveAction,
        isDestructiveAction: isDestructiveAction,
        textStyle: isDestructiveAction
            ? const TextStyle(fontWeight: FontWeight.bold)
            : neutral,
      ),
    ],
  );
  return result ?? OkCancelResult.cancel;
}
