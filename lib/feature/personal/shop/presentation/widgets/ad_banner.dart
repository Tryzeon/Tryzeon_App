import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class AdBanner extends HookConsumerWidget {
  const AdBanner({super.key, required this.adsAsync});
  final AsyncValue<List<String>> adsAsync;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageController = usePageController();

    // Priority 1: Show data if available (even during loading or error)
    if (adsAsync.hasValue) {
      final adImages = adsAsync.value!;

      // Handle empty state
      if (adImages.isEmpty) {
        return const SizedBox.shrink();
      }

      useEffect(() {
        if (adImages.isEmpty) return null;

        final timer = Timer.periodic(const Duration(seconds: 3), (final timer) {
          if (!pageController.hasClients) return;

          // Compute next page without triggering a rebuild via State
          final nextPage = (pageController.page?.round() ?? 0) + 1;
          final targetPage = nextPage >= adImages.length ? 0 : nextPage;

          pageController.animateToPage(
            targetPage,
            duration: AppDuration.slow,
            curve: AppCurves.standard,
          );
        });
        return timer.cancel;
      }, [adImages]);

      final currentPage = useState(0);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (final context, final constraints) {
              // Size the viewport so each page — inset by its horizontal
              // margin — is exactly 16:9, matching the ad artwork.
              final pageWidth = constraints.maxWidth - AppSpacing.md * 2;
              return SizedBox(
                height: pageWidth * 9 / 16,
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (final index) => currentPage.value = index,
                  itemCount: adImages.length,
                  itemBuilder: (final context, final index) {
                    return GestureDetector(
                      onTap: () {
                        // TODO: 點擊廣告導向詳情頁或外部連結
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.cardAll,
                          image: DecorationImage(
                            image: AssetImage(adImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (adImages.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                adImages.length,
                (final index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  width: AppSpacing.sm,
                  height: AppSpacing.sm,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage.value == index
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Priority 2: Show skeleton when loading without data
    if (adsAsync.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: Skeleton.leaf(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.cardAll,
                  color: colorScheme.surfaceContainer,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Priority 3: Error without data - silently hide banner
    return const SizedBox.shrink();
  }
}
