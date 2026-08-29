import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';

class TryonStyleSheet extends HookConsumerWidget {
  const TryonStyleSheet({super.key});

  static const List<String> stylingPresets = ['紮進褲頭', '衣襬放下', '袖子捲起'];

  static const List<String> scenePresets = ['純白攝影棚', '都會街頭', '柔焦自然風景'];

  static const List<String> transitionPresets = ['一鏡到底', '動態跳剪', '柔和淡入淡出'];

  static Future<void> show(final BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final context) => const TryonStyleSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final configAsync = ref.watch(tryonPromptConfigProvider);
    final hasVideoAccess = ref.watch(
      subscriptionCapabilitiesProvider.select(
        (final async) => async.value?.hasVideoAccess ?? false,
      ),
    );
    final stylingController = useTextEditingController();
    final sceneController = useTextEditingController();
    final transitionController = useTextEditingController();
    final isSaving = useState(false);

    // Seed the fields once the stored config lands; later edits are the user's.
    final hasInitialized = useRef(false);
    useEffect(() {
      if (!hasInitialized.value && configAsync.hasValue) {
        hasInitialized.value = true;
        configAsync.whenData((final loaded) {
          stylingController.text = loaded.stylingPrompt ?? '';
          sceneController.text = loaded.scenePrompt ?? '';
          transitionController.text = loaded.transitionPrompt ?? '';
        });
      }
      return null;
    }, [configAsync.hasValue]);

    Future<void> handleSave() async {
      isSaving.value = true;
      final styling = stylingController.text.trim();
      final scene = sceneController.text.trim();
      final transition = transitionController.text.trim();
      await ref
          .read(tryonPromptConfigProvider.notifier)
          .save(
            TryonPromptConfig(
              scenePrompt: scene.isEmpty ? null : scene,
              stylingPrompt: styling.isEmpty ? null : styling,
              transitionPrompt: transition.isEmpty ? null : transition,
            ),
          );
      isSaving.value = false;
      if (context.mounted) Navigator.pop(context);
    }

    return SafeArea(
      bottom: true,
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: colorScheme.onSurface, size: 24),
                  const SizedBox(width: AppSpacing.smMd),
                  Text('自訂試穿風格', style: textTheme.titleLarge),
                ],
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('穿搭細節 Styling', style: textTheme.titleSmall),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '圖片與影片試穿',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _PresetChips(
              controller: stylingController,
              presets: stylingPresets,
              emptyLabel: '沿用原本穿法',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: stylingController,
              decoration: const InputDecoration(hintText: '例如：紮進褲頭'),
              textInputAction: TextInputAction.done,
              maxLines: 2,
              minLines: 1,
            ),

            const SizedBox(height: AppSpacing.mdLg),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('場景 Scene', style: textTheme.titleSmall),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '圖片與影片試穿',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _PresetChips(
              controller: sceneController,
              presets: scenePresets,
              emptyLabel: '沿用原背景',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: sceneController,
              decoration: const InputDecoration(hintText: '例如：純白攝影棚'),
              textInputAction: TextInputAction.done,
              maxLines: 2,
              minLines: 1,
            ),

            // Transition only reaches the video generator, so it stays hidden
            // for anyone who cannot run a video try-on.
            if (hasVideoAccess) ...[
              const SizedBox(height: AppSpacing.mdLg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('轉場 Transition', style: textTheme.titleSmall),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '僅影片試穿',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _PresetChips(
                controller: transitionController,
                presets: transitionPresets,
                emptyLabel: '預設走秀',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: transitionController,
                decoration: const InputDecoration(hintText: '例如：一鏡到底'),
                textInputAction: TextInputAction.done,
                maxLines: 2,
                minLines: 1,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving.value ? null : handleSave,
                child: isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
                      )
                    : const Text('儲存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presets as a single-choice row over [controller]'s text — typing anything
/// off-list surfaces a selected "自訂" chip, so exactly one chip is always lit
/// and an unlisted prompt never reads as "nothing applied".
///
/// [emptyLabel] names what an empty prompt actually does, which differs per
/// field: an empty scene keeps the original background, an empty transition
/// falls back to the default runway motion.
class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.controller,
    required this.presets,
    required this.emptyLabel,
  });

  final TextEditingController controller;
  final List<String> presets;
  final String emptyLabel;

  void _apply(final String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (final context, final value, final _) {
        final current = value.text.trim();
        final isCustom = current.isNotEmpty && !presets.contains(current);
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: Text(emptyLabel),
              selected: current.isEmpty,
              onSelected: (final _) => _apply(''),
            ),
            for (final preset in presets)
              ChoiceChip(
                label: Text(preset),
                selected: current == preset,
                onSelected: (final _) => _apply(preset),
              ),
            // Mirrors the field rather than setting it — re-picking the value
            // already typed is a no-op.
            if (isCustom)
              ChoiceChip(
                label: const Text('自訂'),
                selected: true,
                onSelected: (final _) {},
              ),
          ],
        );
      },
    );
  }
}
