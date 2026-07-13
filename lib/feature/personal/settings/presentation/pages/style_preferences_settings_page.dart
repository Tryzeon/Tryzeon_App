import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/clothing_style/presentation/style_preference_grid.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class StylePreferencesSettingsPage extends HookConsumerWidget {
  const StylePreferencesSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('風格偏好')),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          data: (final profile) {
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _StylePreferencesForm(profile: profile);
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

class _StylePreferencesForm extends HookConsumerWidget {
  const _StylePreferencesForm({required this.profile});

  final UserProfile profile;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final original = useMemoized(
      () => (profile.stylePreferences ?? const <ClothingStyle>[]).toSet(),
    );
    final selected = useState<Set<ClothingStyle>>({...original});
    final isLoading = useState(false);

    final hasChanges = !setEquals(selected.value, original);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    void toggle(final ClothingStyle style) {
      final next = {...selected.value};
      if (!next.add(style)) {
        next.remove(style);
      }
      selected.value = next;
    }

    Future<void> save() async {
      isLoading.value = true;

      final updateUseCase = ref.read(updateStylePreferencesUseCaseProvider);
      final result = await updateUseCase(stylePreferences: selected.value.toList());

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            '可多選，也可以全部取消。',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: StylePreferenceGrid(selected: selected.value, onToggle: toggle),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading.value || !hasChanges ? null : save,
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
    );
  }
}
