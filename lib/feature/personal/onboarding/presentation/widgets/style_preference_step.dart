import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/presentation/style_preference_grid.dart';

import 'package:tryzeon/feature/personal/onboarding/providers/onboarding_notifier.dart';

class StylePreferenceStep extends HookConsumerWidget {
  const StylePreferenceStep({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.smMd),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你喜歡的風格', style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('僅用於推薦你喜歡的風格，不會公開顯示，可略過，日後可在設定中修改。', style: textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: StylePreferenceGrid(
              selected: onboardingState.stylePreferences.toSet(),
              onToggle: notifier.toggleStylePreference,
            ),
          ),
        ],
      ),
    );
  }
}
