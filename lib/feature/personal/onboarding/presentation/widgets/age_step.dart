import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/onboarding/providers/onboarding_notifier.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';

class AgeStep extends HookConsumerWidget {
  const AgeStep({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.smMd),
          Text('你的年齡', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('僅用於推薦符合你的風格，不會公開顯示，日後可在設定中修改。', style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          ...AgeRange.values.map(
            (final range) => RadioListTile<AgeRange>(
              title: Text(range.label),
              value: range,
              // ignore: deprecated_member_use
              groupValue: onboardingState.ageRange,
              // ignore: deprecated_member_use
              onChanged: (final value) {
                if (value != null) notifier.setAgeRange(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
