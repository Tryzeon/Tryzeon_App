import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class TryOnGallery extends StatelessWidget {
  const TryOnGallery({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.onUploadTap,
    required this.tryonImages,
    required this.loadingIndices,
    required this.currentTryonIndex,
    required this.avatarFile,
  });

  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onUploadTap;
  final List<Uint8List> tryonImages;
  final Set<int> loadingIndices;
  final int currentTryonIndex;
  final File? avatarFile;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: currentTryonIndex == -1 ? onUploadTap : null,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: tryonImages.length + 1,
        itemBuilder: (final context, final index) {
          ImageProvider imageProvider;
          if (index > 0) {
            imageProvider = MemoryImage(tryonImages[index - 1]);
          } else if (avatarFile != null) {
            imageProvider = FileImage(avatarFile!);
          } else {
            imageProvider = const AssetImage(AppConstants.defaultProfileImage);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Image with gaplessPlayback
              // 只在非加载状态下显示原图，加载状态下显示SVG骨架
              if (loadingIndices.contains(index - 1))
                Skeletonizer(
                  enabled: true,
                  child: Skeleton.shade(
                    child: SvgPicture.asset(
                      AppConstants.tryOnSkeleton,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Image(image: imageProvider, fit: BoxFit.cover, gaplessPlayback: true),

              // Gradient overlay (only when not loading and not showing skeleton)
              if (!loadingIndices.contains(index - 1)) ...[
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withValues(alpha: 0.3),
                        Colors.transparent,
                        colorScheme.surface.withValues(alpha: 0.3),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                if (avatarFile == null)
                  Align(
                    alignment: const Alignment(0, 0.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: colorScheme.surface.withValues(alpha: 0.3),
                          child: Text(
                            '點擊上傳照片',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
