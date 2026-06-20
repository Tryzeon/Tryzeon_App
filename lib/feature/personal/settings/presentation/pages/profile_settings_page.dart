import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class PersonalProfileSettingsPage extends HookConsumerWidget {
  const PersonalProfileSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('個人資料')),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          data: (final profile) {
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _PersonalProfileForm(profile: profile);
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

class _PersonalProfileForm extends HookConsumerWidget {
  const _PersonalProfileForm({required this.profile});

  final UserProfile profile;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController(text: profile.name);
    final ageRange = useState<AgeRange?>(profile.ageRange);
    final gender = useState<Gender?>(profile.gender);
    final isLoading = useState(false);

    final userName = useValueListenable(nameController).text;

    final nameChanged = userName.trim() != profile.name;
    final ageChanged = ageRange.value != profile.ageRange;
    final genderChanged = gender.value != profile.gender;
    final hasChanges = nameChanged || ageChanged || genderChanged;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Future<void> updateProfile() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      final updateUseCase = ref.read(updateUserProfileUseCaseProvider);
      final result = await updateUseCase(
        name: nameController.text.trim(),
        gender: gender.value,
        ageRange: ageRange.value,
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(userProfileProvider);
        if (context.mounted) context.pop();
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你的名字不會被公開顯示。',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validateUserName,
              decoration: const InputDecoration(labelText: '姓名'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '年齡',
              style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...AgeRange.values.map(
              (final value) => RadioListTile<AgeRange>(
                contentPadding: EdgeInsets.zero,
                title: Text(value.label),
                value: value,
                // ignore: deprecated_member_use
                groupValue: ageRange.value,
                // ignore: deprecated_member_use
                onChanged: (final selected) => ageRange.value = selected,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '性別',
              style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...Gender.values.map(
              (final value) => RadioListTile<Gender>(
                contentPadding: EdgeInsets.zero,
                title: Text(value.label),
                value: value,
                // ignore: deprecated_member_use
                groupValue: gender.value,
                // ignore: deprecated_member_use
                onChanged: (final selected) => gender.value = selected,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading.value || !hasChanges ? null : updateProfile,
                child: isLoading.value
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
