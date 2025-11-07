import 'package:flutter/material.dart';
import 'dart:async';

class AdBanner extends StatefulWidget {
  final List<String> adImages;

  const AdBanner({
    super.key,
    required this.adImages,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _currentPage);

    // 自動輪播邏輯
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < widget.adImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.adImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // TODO: 點擊廣告導向詳情頁或外部連結
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(widget.adImages[index]),
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