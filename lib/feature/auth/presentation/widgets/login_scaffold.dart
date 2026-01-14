import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CustomizeScaffold extends HookConsumerWidget {
  const CustomizeScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Custom vibrant colors
    const backgroundColor = Color(0xFFF8FAFC); // Slate 50
    const blob1Color = Color(0xFF6366F1); // Indigo 500
    const blob2Color = Color(0xFFEC4899); // Pink 500

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Gradient Mesh Effect
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    blob1Color.withValues(alpha: 0.2),
                    blob1Color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    blob2Color.withValues(alpha: 0.2),
                    blob2Color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Extra middle blob for richness
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.1), // Sky blue
                    const Color(0xFF0EA5E9).withValues(alpha: 0.0),
                  ],
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
