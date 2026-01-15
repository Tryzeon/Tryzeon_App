import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CustomizeScaffold extends HookConsumerWidget {
  const CustomizeScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Custom Design Tokens - Clean Premium Light
    const backgroundColor = Color(0xFFF8FAFC); // Slate 50
    // Soft, aurora-like colors
    const blob1Color = Color(0xFFE0E7FF); // Indigo 100
    const blob2Color = Color(0xFFFAE8FF); // Fuchsia 100
    const blob3Color = Color(0xFFE0F2FE); // Sky 100

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Top-Left Blob (Indigo/Purple)
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [blob1Color, blob1Color.withValues(alpha: 0.0)],
                  radius: 0.6,
                ),
              ),
            ),
          ),

          // 2. Bottom-Right Blob (Pink/Fuchsia)
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [blob2Color, blob2Color.withValues(alpha: 0.0)],
                  radius: 0.6,
                ),
              ),
            ),
          ),

          // 3. Middle-Right Accent (Sky Blue) - adds depth
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    blob3Color.withValues(alpha: 0.8),
                    blob3Color.withValues(alpha: 0.0),
                  ],
                  radius: 0.6,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(child: body),
        ],
      ),
    );
  }
}
