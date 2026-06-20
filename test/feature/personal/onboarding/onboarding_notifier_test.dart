import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('initial state has no gender, no ageRange and empty styles', () {
    final container = makeContainer();
    final state = container.read(onboardingProvider);
    expect(state.currentStep, 0);
    expect(state.gender, isNull);
    expect(state.ageRange, isNull);
    expect(state.stylePreferences, isEmpty);
  });

  test('setAgeRange stores the selected range', () {
    final container = makeContainer();
    final notifier = container.read(onboardingProvider.notifier);

    notifier.setAgeRange(AgeRange.age25to34);
    expect(container.read(onboardingProvider).ageRange, AgeRange.age25to34);

    notifier.setAgeRange(AgeRange.age18to24);
    expect(container.read(onboardingProvider).ageRange, AgeRange.age18to24);
  });

  test('setGender stores the selected gender', () {
    final container = makeContainer();
    container.read(onboardingProvider.notifier).setGender(Gender.female);
    expect(container.read(onboardingProvider).gender, Gender.female);
  });

  test('toggleStylePreference adds then removes a style', () {
    final container = makeContainer();
    final notifier = container.read(onboardingProvider.notifier);

    notifier.toggleStylePreference(ClothingStyle.casual);
    expect(container.read(onboardingProvider).stylePreferences, [ClothingStyle.casual]);

    notifier.toggleStylePreference(ClothingStyle.casual);
    expect(container.read(onboardingProvider).stylePreferences, isEmpty);
  });

  test('nextStep advances without requiring any selection and caps at last step', () {
    final container = makeContainer();
    final notifier = container.read(onboardingProvider.notifier);

    // No gender/age selected — navigation must not be gated.
    notifier.nextStep();
    expect(container.read(onboardingProvider).currentStep, 1);
    notifier.nextStep();
    expect(container.read(onboardingProvider).currentStep, 2);
    notifier.nextStep();
    expect(container.read(onboardingProvider).currentStep, 2);
  });

  test('previousStep goes back and caps at first step', () {
    final container = makeContainer();
    final notifier = container.read(onboardingProvider.notifier);

    notifier.nextStep();
    notifier.nextStep();
    expect(container.read(onboardingProvider).currentStep, 2);

    notifier.previousStep();
    expect(container.read(onboardingProvider).currentStep, 1);
    notifier.previousStep();
    notifier.previousStep();
    expect(container.read(onboardingProvider).currentStep, 0);
  });
}
