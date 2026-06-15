import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A [FormField] whose value is driven by an external [ValueNotifier], the same
/// way [TextFormField] is driven by a [TextEditingController].
///
/// The notifier is the single source of truth: callers mutate `controller.value`
/// (directly, or programmatically e.g. when pruning on a dependency change) and
/// this field mirrors every change into the form for validation — no manual
/// `didChange` plumbing at the call site.
///
/// Changes made while a build is in progress (e.g. from a hook effect) are
/// deferred to the end of the frame, because `didChange` marks the ancestor
/// [Form] dirty and that is illegal mid-build.
class SelectionFormField<T> extends FormField<T> {
  SelectionFormField({
    super.key,
    required this.controller,
    required super.builder,
    super.validator,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
    super.enabled,
  }) : super(initialValue: controller.value);

  final ValueNotifier<T> controller;

  @override
  FormFieldState<T> createState() => _SelectionFormFieldState<T>();
}

class _SelectionFormFieldState<T> extends FormFieldState<T> {
  SelectionFormField<T> get _field => widget as SelectionFormField<T>;

  @override
  void initState() {
    super.initState();
    _field.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(final SelectionFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_field.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _field.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _field.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (value == _field.controller.value) return;
    // If a frame is being built (e.g. the notifier was mutated from a hook
    // effect), defer; otherwise sync immediately for snappy event-driven edits.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((final _) {
        if (mounted && value != _field.controller.value) {
          didChange(_field.controller.value);
        }
      });
    } else {
      didChange(_field.controller.value);
    }
  }
}
