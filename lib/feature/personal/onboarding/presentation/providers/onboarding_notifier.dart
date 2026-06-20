import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/onboarding/providers/personal_onboarding_providers.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'onboarding_notifier.freezed.dart';
part 'onboarding_notifier.g.dart';

@freezed
sealed class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) final int currentStep,
    final Gender? gender,
    final int? age,
    @Default([]) final List<ClothingStyle> stylePreferences,
    @Default(false) final bool isSubmitting,
  }) = _OnboardingState;
}

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  void setGender(final Gender gender) {
    state = state.copyWith(gender: gender);
  }

  void setAge(final int? age) {
    state = state.copyWith(age: age);
  }

  void toggleStylePreference(final ClothingStyle style) {
    final current = List<ClothingStyle>.from(state.stylePreferences);
    if (current.contains(style)) {
      current.remove(style);
    } else {
      current.add(style);
    }
    state = state.copyWith(stylePreferences: current);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<Result<void, Failure>> completeOnboarding() async {
    state = state.copyWith(isSubmitting: true);

    final original = await ref.read(userProfileProvider.future);
    if (original == null) {
      state = state.copyWith(isSubmitting: false);
      return const Err(AuthFailure('找不到使用者資料'));
    }

    final useCase = ref.read(completeOnboardingUseCaseProvider);
    final result = await useCase(
      gender: state.gender,
      age: state.age,
      stylePreferences: state.stylePreferences.isEmpty ? null : state.stylePreferences,
    );

    state = state.copyWith(isSubmitting: false);

    if (result.isSuccess) {
      ref.invalidate(userProfileProvider);
    }

    return result;
  }
}
