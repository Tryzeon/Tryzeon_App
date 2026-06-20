import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

import '../providers/onboarding_notifier.dart';

class AgeStep extends HookConsumerWidget {
  const AgeStep({super.key});

  static const _minAge = 13;
  static const _maxAge = 100;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(onboardingProvider.notifier);

    final controller = useFixedExtentScrollController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.smMd),
          Text('你的年齡', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('我們會優先推薦符合你年齡的風格，可略過，日後可在設定中修改。', style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: SizedBox(
              width: 160,
              height: 300,
              child: CupertinoPicker(
                scrollController: controller,
                itemExtent: 48,
                onSelectedItemChanged: (final index) {
                  notifier.setAge(index == 0 ? null : _minAge + index - 1);
                },
                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                  background: colorScheme.primaryContainer.withValues(
                    alpha: AppOpacity.strong,
                  ),
                ),
                children: [
                  Center(child: Text('不指定', style: textTheme.headlineSmall)),
                  ...List.generate(
                    _maxAge - _minAge + 1,
                    (final i) => Center(
                      child: Text('${_minAge + i} 歲', style: textTheme.headlineSmall),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
