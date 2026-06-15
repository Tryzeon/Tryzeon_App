import 'dart:math' as math;

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/providers/chat_event.dart';
import 'package:tryzeon/feature/personal/chat/presentation/providers/chat_notifier.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_bubble.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_header.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_input_bar.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_starter_chips.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_thinking_bubble.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/recommendation_bubble.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final controller = useTextEditingController();
    final scrollController = useScrollController();
    final state = ref.watch(chatProvider);

    void scrollToBottom() {
      Future.delayed(AppDuration.slow, () {
        if (context.mounted && scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: AppDuration.slow,
            curve: AppCurves.enter,
          );
        }
      });
    }

    ref.listen(
      chatProvider.select((final s) => s.messages.length),
      (final _, final _) => scrollToBottom(),
    );
    ref.listen(chatProvider.select((final s) => s.isLoading), (final _, final isLoading) {
      if (isLoading) scrollToBottom();
    });

    final notifier = ref.watch(chatProvider.notifier);
    useEffect(() {
      final subscription = notifier.events.listen((final event) {
        if (!context.mounted) return;
        switch (event) {
          case ChatRateLimited():
            UpgradeDialog.show(
              context,
              title: '對話次數已達上限',
              content: '今天的對話次數已達上限\n升級方案就能繼續聊呦！',
            );
        }
      });
      return subscription.cancel;
    }, [notifier]);

    void sendMessage(final String text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      controller.clear();
      ref.read(chatProvider.notifier).sendMessage(trimmed);
    }

    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final safeAreaBottom = mediaQuery.viewPadding.bottom;

    final inputEnabled = !state.isLoading;
    // Starter chips only while the conversation is just the greeting.
    final showStarters = state.messages.length <= 1 && !state.isLoading;

    final isIOS26 = PlatformInfo.isIOS26OrHigher();

    final bodyBottomOffset = isIOS26
        ? 0.0
        : PlatformInfo.isIOS
        ? AppSpacing.iosTabBarHeight + safeAreaBottom
        : AppSpacing.androidNavBarHeight;

    final restingSpacing = isIOS26
        ? safeAreaBottom + AppSpacing.iosTabBarHeight + AppSpacing.sm
        : AppSpacing.sm;

    final bottomSpacing = isKeyboardOpen
        ? math.max(restingSpacing, keyboardHeight - bodyBottomOffset)
        : restingSpacing;

    return Material(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ChatHeader(
              onRefresh: () async {
                final result = await showOkCancelAlertDialog(
                  context: context,
                  message: '你確定要重設整個對話嗎？',
                  okLabel: '確定',
                  cancelLabel: '取消',
                  isDestructiveAction: true,
                );

                if (result == OkCancelResult.ok) {
                  ref.read(chatProvider.notifier).reset();
                }
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (final context, final index) {
                    if (index < state.messages.length) {
                      final message = state.messages[index];
                      final rec = message.recommendation;
                      if (rec != null) {
                        return RecommendationBubble(recommendation: rec);
                      }
                      return ChatBubble(message: message);
                    }
                    return const ChatThinkingBubble();
                  },
                ),
              ),
            ),
            if (showStarters) ChatStarterChips(onTap: sendMessage),
            ChatInputBar(
              controller: controller,
              enabled: inputEnabled,
              onSend: () => sendMessage(controller.text),
            ),
            SizedBox(height: bottomSpacing),
          ],
        ),
      ),
    );
  }
}
