import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AdBanner extends HookWidget {
  const AdBanner({super.key, required this.adImages});
  final List<String> adImages;

  @override
  Widget build(final BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);

    useEffect(() {
      if (adImages.isEmpty) return null;

      final timer = Timer.periodic(const Duration(seconds: 3), (final timer) {
        if (!pageController.hasClients) return;

        if (currentPage.value < adImages.length - 1) {
          currentPage.value++;
        } else {
          currentPage.value = 0;
        }

        pageController.animateToPage(
          currentPage.value,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [adImages]); // Re-run effect when adImages changes

    if (adImages.isEmpty) {
      return const SizedBox(height: 180);
    }

    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: pageController,
        itemCount: adImages.length,
        onPageChanged: (final index) {
          currentPage.value = index;
        },
        itemBuilder: (final context, final index) {
          return GestureDetector(
            onTap: () {
              // TODO: 點擊廣告導向詳情頁或外部連結
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
  }
}
