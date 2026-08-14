import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Dismisses the keyboard when a tap lands outside the focused text field.
///
/// Flutter only drops focus on tap-outside on desktop, so on iOS a field whose
/// keyboard has no usable return key (numeric pads, multiline) keeps the
/// keyboard open with no way out. Overriding the tap-outside intents is the
/// framework's supported hook for changing that.
class AppKeyboardDismisser extends HookWidget {
  const AppKeyboardDismisser({super.key, required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final downPosition = useRef<Offset?>(null);

    void handleTapDown(final EditableTextTapOutsideIntent intent) {
      // Only touch needs the tap-vs-scroll check; other pointers keep the
      // framework's unfocus-on-down behaviour.
      if (intent.pointerDownEvent.kind != PointerDeviceKind.touch) {
        intent.focusNode.unfocus();
        return;
      }
      downPosition.value = intent.pointerDownEvent.position;
    }

    void handleTapUp(final EditableTextTapUpOutsideIntent intent) {
      final down = downPosition.value;
      downPosition.value = null;
      if (down == null) return;

      // A pointer that travelled past the slop was a scroll, not a tap.
      if ((down - intent.pointerUpEvent.position).distance < kTouchSlop) {
        intent.focusNode.unfocus();
      }
    }

    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
          onInvoke: handleTapDown,
        ),
        EditableTextTapUpOutsideIntent: CallbackAction<EditableTextTapUpOutsideIntent>(
          onInvoke: handleTapUp,
        ),
      },
      child: child,
    );
  }
}
