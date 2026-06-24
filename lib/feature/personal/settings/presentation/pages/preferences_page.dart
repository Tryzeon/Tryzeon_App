import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';

class PreferencesPage extends HookConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final recommendNearbyShopsAsync = ref.watch(recommendNearbyShopsProvider);

    Future<void> handleRecommendNearbyShopsToggle(
      final bool isNearbyShopsRecommendationEnabled,
    ) async {
      if (isNearbyShopsRecommendationEnabled) {
        final locationService = ref.read(locationServiceProvider);
        final permission = await locationService.requestPermission();

        if (!context.mounted) return;

        if (permission == LocationPermission.denied) {
          TopNotification.show(context, message: '需要開啟定位權限才能使用此功能');
          return;
        }

        if (permission == LocationPermission.deniedForever) {
          final result = await showAppOkCancelDialog(
            context: context,
            title: '需要定位權限',
            message: '為了推薦附近的店家，我們需要您的位置權限。請前往設定開啟權限。',
            okLabel: '前往設定',
            cancelLabel: '取消',
          );
          if (result == OkCancelResult.ok) {
            await Geolocator.openAppSettings();
          }
          return;
        }
      }
      ref
          .read(recommendNearbyShopsProvider.notifier)
          .toggle(isNearbyShopsRecommendationEnabled);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('偏好設定')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ToggleRow(
                title: '推薦附近店家',
                subtitle: '根據你的位置推薦附近的優質店家',
                value: recommendNearbyShopsAsync.value ?? false,
                isLoading: recommendNearbyShopsAsync.isLoading,
                onChanged: recommendNearbyShopsAsync.isLoading
                    ? null
                    : handleRecommendNearbyShopsToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: isLoading
              ? SizedBox(
                  width: AppSpacing.mdLg,
                  height: AppSpacing.mdLg,
                  child: CircularProgressIndicator(
                    strokeWidth: AppStroke.regular,
                    color: colorScheme.onSurface,
                  ),
                )
              : Switch(value: value, onChanged: onChanged),
        ),
        const Divider(),
      ],
    );
  }
}
