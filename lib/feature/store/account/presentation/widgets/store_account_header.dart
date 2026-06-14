import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

class StoreAccountHeader extends StatelessWidget {
  const StoreAccountHeader({super.key, required this.profile});

  final StoreProfile? profile;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final storeName = (profile?.name.isNotEmpty ?? false)
        ? profile!.name
        : 'Tryzeon Studio';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '歡迎回來，',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  storeName,
                  style: textTheme.displaySmall?.copyWith(fontStyle: FontStyle.normal),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '設定',
                onPressed: () => context.push(AppRoutes.storeSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
