import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/resolved_outfit_slot.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/outfit_pick_card.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';

class RecommendationBubble extends HookConsumerWidget {
  const RecommendationBubble({super.key, required this.recommendation});

  final ChatRecommendation recommendation;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final styleSheet = useMemoized(
      () => MarkdownStyleSheet.fromTheme(theme).copyWith(p: textTheme.bodyLarge),
      [theme],
    );

    final resolvedAsync = recommendation.slots.isEmpty
        ? const AsyncValue<List<ResolvedOutfitSlot>>.data([])
        : ref.watch(resolvedOutfitProvider(recommendation.slots));

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          border: Border.all(color: colorScheme.outline),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.card),
            topRight: Radius.circular(AppRadius.card),
            bottomRight: Radius.circular(AppRadius.card),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recommendation.description.isNotEmpty)
              MarkdownBody(
                data: recommendation.description,
                selectable: true,
                styleSheet: styleSheet,
              ),
            resolvedAsync.when(
              data: (final slots) => _SlotsList(slots: slots),
              loading: () => const SizedBox.shrink(),
              error: (final _, final _) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  '推薦商品載入失敗',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotsList extends StatelessWidget {
  const _SlotsList({required this.slots});
  final List<ResolvedOutfitSlot> slots;

  @override
  Widget build(final BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slot in slots) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(),
          ),
          _SlotSection(slot: slot),
        ],
      ],
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({required this.slot});
  final ResolvedOutfitSlot slot;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isEmpty = slot is ResolvedOutfitSlotEmpty;
    final (label, reason, isWardrobe) = switch (slot) {
      ResolvedOutfitSlotWardrobe(:final slotLabel, :final reason) => (
        slotLabel,
        reason,
        true,
      ),
      ResolvedOutfitSlotShop(:final slotLabel, :final reason) => (
        slotLabel,
        reason,
        false,
      ),
      ResolvedOutfitSlotEmpty(:final slotLabel, :final reason) => (
        slotLabel,
        reason,
        false,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: textTheme.titleSmall),
            if (!isEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              _SourceChip(isWardrobe: isWardrobe),
            ],
          ],
        ),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            reason,
            style: textTheme.bodySmall,
          ),
        ],
        if (!isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: OutfitPickCard.size,
            child: _SlotRow(slot: slot),
          ),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot});
  final ResolvedOutfitSlot slot;

  @override
  Widget build(final BuildContext context) {
    final (count, cardBuilder) = switch (slot) {
      ResolvedOutfitSlotWardrobe(:final items) => (
        items.length,
        (final BuildContext ctx, final int i) =>
            OutfitPickCard.wardrobe(item: items[i], context: ctx),
      ),
      ResolvedOutfitSlotShop(:final products) => (
        products.length,
        (final BuildContext ctx, final int i) =>
            OutfitPickCard.shop(product: products[i], context: ctx),
      ),
      ResolvedOutfitSlotEmpty() => (0, null),
    };

    if (cardBuilder == null) return const SizedBox.shrink();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: count,
      separatorBuilder: (final _, final _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: cardBuilder,
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.isWardrobe});
  final bool isWardrobe;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final (bg, fg, text) = isWardrobe
        ? (colorScheme.secondaryContainer, colorScheme.onSecondaryContainer, '你的衣櫃')
        : (colorScheme.primaryContainer, colorScheme.onPrimaryContainer, '推薦商品');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Text(text, style: textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}
