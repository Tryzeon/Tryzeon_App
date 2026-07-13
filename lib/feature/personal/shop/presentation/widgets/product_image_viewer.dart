import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ProductImageViewer extends HookWidget {
  const ProductImageViewer({
    required this.imageUrls,
    required this.imagePaths,
    super.key,
  });

  final List<String> imageUrls;
  final List<String> imagePaths;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageController = usePageController();
    final currentPage = useState(0);

    if (imageUrls.isEmpty) {
      return Container(
        height: 400,
        width: double.infinity,
        color: colorScheme.surfaceContainer,
        child: const Icon(Icons.image_not_supported, size: 50),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (final index) => currentPage.value = index,
            itemCount: imageUrls.length,
            itemBuilder: (final context, final index) {
              final imageUrl = imageUrls[index];
              final imagePath = imagePaths.length > index ? imagePaths[index] : null;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (final context) {
                        final cs = Theme.of(context).colorScheme;
                        return Scaffold(
                          backgroundColor: cs.scrim,
                          appBar: AppBar(
                            backgroundColor: cs.scrim,
                            iconTheme: IconThemeData(color: cs.onInverseSurface),
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                cacheKey: imagePath,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (final context, final url) =>
                                    const Center(child: CircularProgressIndicator()),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: AppRadius.cardAll,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    cacheKey: imagePath,
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.cover,
                    placeholder: (final context, final url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (final context, final url, final error) =>
                        const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              );
            },
          ),
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
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
          ),
      ],
    );
  }
}
