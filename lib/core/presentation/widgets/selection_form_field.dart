import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A [FormField] driven by an external [ValueNotifier], the way [TextFormField]
/// is driven by a [TextEditingController].
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
    // `didChange` marks the ancestor [Form] dirty, which is illegal mid-build,
    // so a change arriving during a build (e.g. from a hook effect) is deferred.
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
