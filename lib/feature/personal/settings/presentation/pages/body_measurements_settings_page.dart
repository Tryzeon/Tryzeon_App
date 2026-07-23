import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/body_measurements/presentation/mappers/body_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class BodyMeasurementsSettingsPage extends HookConsumerWidget {
  const BodyMeasurementsSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('身形資料')),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          data: (final profile) {
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _BodyMeasurementsForm(profile: profile);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, final stack) => ErrorView(
            message: error.displayMessage(context),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
      ),
    );
  }
}

class _BodyMeasurementsForm extends HookConsumerWidget {
  const _BodyMeasurementsForm({required this.profile});

  final UserProfile profile;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final measurementControllers = <BodyMeasurementType, TextEditingController>{};
    for (final type in BodyMeasurementType.values) {
      measurementControllers[type] = useTextEditingController(
        text: profile.measurements?[type]?.toString() ?? '',
      );
    }

    final isLoading = ref.watch(profileEditProvider).isLoading;
    var hasChanges = false;
    var filledCount = 0;

    for (final type in BodyMeasurementType.values) {
      final currentValue = useValueListenable(measurementControllers[type]!).text;
      final originalValue = profile.measurements?[type]?.toString() ?? '';
      final currentDouble = double.tryParse(currentValue);
      final originalDouble = double.tryParse(originalValue);

      if (currentDouble != originalDouble) {
        hasChanges = true;
      }
      if (currentDouble != null) {
        filledCount++;
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Future<void> updateMeasurements() async {
      if (!formKey.currentState!.validate()) return;

      final measurements = BodyMeasurements.fromValues({
        for (final entry in measurementControllers.entries)
          entry.key: double.tryParse(entry.value.text),
      });

      final result = await ref
          .read(profileEditProvider.notifier)
          .updateBodyMeasurements(measurements);

      if (!context.mounted) return;

      if (result.isSuccess) {
        context.pop();
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _UsageInfoCard(),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '填寫進度',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    '$filledCount / ${BodyMeasurements.fieldCount}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _MeasurementGrid(
              types: BodyMeasurementType.values,
              controllers: measurementControllers,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading || !hasChanges ? null : updateMeasurements,
                child: isLoading
                    ? SizedBox(
                        width: AppSpacing.mdLg,
                        height: AppSpacing.mdLg,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: AppStroke.regular,
                        ),
                      )
                    : const Text('儲存'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _MeasurementGrid extends StatelessWidget {
  const _MeasurementGrid({required this.types, required this.controllers});

  final List<BodyMeasurementType> types;
  final Map<BodyMeasurementType, TextEditingController> controllers;

  @override
  Widget build(final BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < types.length; i += 2) {
      final left = types[i];
      final right = i + 1 < types.length ? types[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MeasurementField(type: left, controller: controllers[left]!),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _MeasurementField(type: right, controller: controllers[right]!),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({required this.type, required this.controller});

  final BodyMeasurementType type;
  final TextEditingController controller;

  @override
  Widget build(final BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      validator: AppValidators.validateMeasurement,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(labelText: type.label, suffixText: 'cm'),
    );
  }
}

class _UsageInfoCard extends StatelessWidget {
  const _UsageInfoCard();

  static const List<String> _usagePoints = [
    '自動計算你的合身推薦尺寸。',
    '試穿效果更貼近實際穿上的樣子。',
    '資料僅用於上述用途，不會對外顯示。',
  ];

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smMd,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '我們如何使用你的身形資料',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          for (final point in _usagePoints)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.smMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '・',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      point,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
