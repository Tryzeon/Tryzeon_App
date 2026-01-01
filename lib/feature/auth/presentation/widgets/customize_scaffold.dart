import 'package:flutter/material.dart';

class CustomizeScaffold extends StatelessWidget {
  const CustomizeScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Ambient Background Blobs - Top Left
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Ambient Background Blobs - Bottom Right
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.15),
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
