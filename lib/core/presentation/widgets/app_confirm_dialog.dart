import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';

export 'package:adaptive_dialog/adaptive_dialog.dart' show OkCancelResult;

/// Clean Luxe replacement for [showOkCancelAlertDialog].
///
/// Renders an adaptive (Material / Cupertino) OK-Cancel confirmation, but the
/// neutral actions (cancel + non-destructive confirm) use charcoal `onSurface`
/// instead of the platform accent (lavender on Material, system blue on iOS).
/// Destructive confirms stay red — both platforms resolve that from
/// [AlertDialogAction.isDestructiveAction].
///
/// Mirrors the subset of [showOkCancelAlertDialog]'s API the app actually uses
/// so call sites only swap the function name.
Future<OkCancelResult> showAppOkCancelDialog({
  required final BuildContext context,
  final String? title,
  final String? message,
  final String? okLabel,
  final String? cancelLabel,
  final bool isDestructiveAction = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  // Neutral charcoal label. Destructive confirms must pass an empty TextStyle
  // so the Cupertino destructive red is not overridden by a color merge.
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
