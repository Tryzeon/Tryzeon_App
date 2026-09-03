import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';

/// Tall enough to fill in, short enough that the page behind still shows —
/// which is what says "sheet" rather than "page".
const double _restingHeightFraction = 0.7;
const double _minHeightFraction = 0.5;
const double _expandedHeightFraction = 0.9;

class TryonSettingsSheet extends HookWidget {
  const TryonSettingsSheet({super.key});

  static Future<void> show(final BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final context) => const TryonSettingsSheet(),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final sheetController = useMemoized(DraggableScrollableController.new);
    useEffect(() => sheetController.dispose, [sheetController]);

    return DraggableScrollableSheet(
      expand: false,
      controller: sheetController,
      initialChildSize: _restingHeightFraction,
      minChildSize: _minHeightFraction,
      maxChildSize: _expandedHeightFraction,
      builder: (final context, final scrollController) => _TryonSettingsForm(
        scrollController: scrollController,
        sheetController: sheetController,
      ),
    );
  }
}

class _TryonSettingsForm extends HookConsumerWidget {
  const _TryonSettingsForm({
    required this.scrollController,
    required this.sheetController,
  });

  /// The sheet's own controller. Attaching it to the settings list is what lets
  /// dragging that list resize the sheet instead of only scrolling it.
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;

  static const List<String> stylingPresets = ['紮進褲頭', '衣襬放下', '袖子捲起'];

  static const List<String> scenePresets = ['純白攝影棚', '都會街頭', '柔焦自然風景'];

  static const List<String> transitionPresets = ['一鏡到底', '動態跳剪', '柔和淡入淡出'];

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final preferencesAsync = ref.watch(tryonPreferencesProvider);
    final hasVideoAccess = ref.watch(
      subscriptionCapabilitiesProvider.select(
        (final async) => async.value?.hasVideoAccess ?? false,
      ),
    );
    final stylingController = useTextEditingController();
    final sceneController = useTextEditingController();
    final transitionController = useTextEditingController();
    final engine = useState(TryonEngine.standard);

    void commit() {
      final styling = stylingController.text.trim();
      final scene = sceneController.text.trim();
      final transition = transitionController.text.trim();
      ref
          .read(tryonPreferencesProvider.notifier)
          .apply(
            TryonPreferences(
              scenePrompt: scene.isEmpty ? null : scene,
              stylingPrompt: styling.isEmpty ? null : styling,
              transitionPrompt: transition.isEmpty ? null : transition,
              engine: engine.value,
            ),
          );
    }

    // Seed the fields once the stored preferences land, then follow every edit
    // after that: there is no save button, so an edit this misses is lost.
    final hasInitialized = useRef(false);
    useEffect(() {
      if (hasInitialized.value || !preferencesAsync.hasValue) return null;
      hasInitialized.value = true;

      final loaded = preferencesAsync.requireValue;
      stylingController.text = loaded.stylingPrompt ?? '';
      sceneController.text = loaded.scenePrompt ?? '';
      transitionController.text = loaded.transitionPrompt ?? '';
      engine.value = loaded.engine;

      final controllers = [stylingController, sceneController, transitionController];
      for (final controller in controllers) {
        controller.addListener(commit);
      }
      return () {
        for (final controller in controllers) {
          controller.removeListener(commit);
        }
      };
    }, [preferencesAsync.hasValue]);

    // The keyboard covers roughly a third of the screen, which at the resting
    // height would leave the field it was opened for barely visible.
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    useEffect(() {
      if (isKeyboardOpen && sheetController.isAttached) {
        sheetController.animateTo(
          _expandedHeightFraction,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      return null;
    }, [isKeyboardOpen]);

    return SafeArea(
      bottom: true,
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
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
                  Text('試穿設定', style: textTheme.titleLarge),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('進階模型 Beta', style: textTheme.titleSmall),
                      subtitle: Text(
                        '實驗性質的模型，可能會有不穩定的結果',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: engine.value == TryonEngine.advanced,
                      onChanged: (final isAdvanced) {
                        engine.value = isAdvanced
                            ? TryonEngine.advanced
                            : TryonEngine.standard;
                        commit();
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

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
                      emptyLabel: '不指定',
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

                    // Transition only reaches the video generator.
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

                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing anything off-list surfaces a selected "自訂" chip, so exactly one chip
/// is always lit and an unlisted prompt never reads as "nothing applied".
/// [emptyLabel] differs per field: an empty scene keeps the original
/// background, an empty transition falls back to the default runway motion.
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
