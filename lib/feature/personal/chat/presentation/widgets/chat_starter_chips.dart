import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatStarterChips extends StatelessWidget {
  const ChatStarterChips({super.key, required this.onTap});

  final ValueChanged<String> onTap;

  static const List<String> _prompts = ['上班約會穿搭', '週末休閒風', '幫我搭一件白襯衫', '參加婚禮要穿什麼'];

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxl + AppSpacing.sm,
      child: Stack(
        children: [
          ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            itemCount: _prompts.length,
            itemBuilder: (final context, final index) {
              final prompt = _prompts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: ActionChip(label: Text(prompt), onPressed: () => onTap(prompt)),
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: AppSpacing.xl,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
