import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ProductDangerZone extends StatelessWidget {
  const ProductDangerZone({
    super.key,
    required this.onDelete,
    this.isSaving = false,
    this.isDeleting = false,
  });

  final VoidCallback onDelete;
  final bool isSaving;
  final bool isDeleting;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '危險操作',
                style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.smMd),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (isSaving || isDeleting) ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                  child: isDeleting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: AppStroke.regular,
                            color: colorScheme.error,
                          ),
                        )
                      : const Text('刪除商品'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
