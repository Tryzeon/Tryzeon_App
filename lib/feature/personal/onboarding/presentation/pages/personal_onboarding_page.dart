import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/onboarding/presentation/widgets/age_step.dart';
import 'package:tryzeon/feature/personal/onboarding/presentation/widgets/gender_selection_step.dart';
import 'package:tryzeon/feature/personal/onboarding/presentation/widgets/style_preference_step.dart';
import 'package:typed_result/typed_result.dart';

import '../providers/onboarding_notifier.dart';

class PersonalOnboardingPage extends HookConsumerWidget {
  const PersonalOnboardingPage({super.key});

  static const _totalSteps = 3;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageController = usePageController();
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final currentStep = onboardingState.currentStep;

    // Animate page when step changes
    ref.listen(onboardingProvider, (final previous, final next) {
      if ((previous?.currentStep ?? 0) != next.currentStep) {
        pageController.animateToPage(
          next.currentStep,
          duration: AppDuration.slow,
          curve: AppCurves.standard,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: notifier.previousStep,
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Step content
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [GenderSelectionStep(), AgeStep(), StylePreferenceStep()],
            ),
          ),

          // Bottom Action Area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmoothPageIndicator(
                    controller: pageController,
                    count: _totalSteps,
                    effect: ExpandingDotsEffect(
                      dotHeight: AppSpacing.sm,
                      dotWidth: AppSpacing.sm,
                      spacing: AppSpacing.sm,
                      activeDotColor: colorScheme.primary,
                      dotColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (currentStep < _totalSteps - 1)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: notifier.nextStep,
                        child: const Text('下一步'),
                      ),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: onboardingState.isSubmitting
                                ? null
                                : () => _handleComplete(context, notifier),
                            child: onboardingState.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: AppStroke.regular,
                                    ),
                                  )
                                : const Text('完成'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComplete(
    final BuildContext context,
    final OnboardingNotifier notifier,
  ) async {
    final result = await notifier.completeOnboarding();
    if (!context.mounted) return;

    switch (result) {
      case Err(:final error):
        TopNotification.show(context, message: error.displayMessage(context));
      case Ok():
        break;
    }
  }
}
