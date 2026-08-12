import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'personal_tab.g.dart';

/// The personal shell's bottom-nav tabs, in branch order.
enum PersonalTab {
  home(label: '首頁', icon: Icons.home_outlined),
  shop(label: '試衣間', icon: Icons.shopping_cart_outlined),
  chat(label: '聊天', icon: Icons.chat_outlined),
  wardrobe(label: '衣櫃', icon: Icons.checkroom_outlined),
  account(label: '我的', icon: Icons.person_outline);

  const PersonalTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// A tap on the already-selected tab. [sequence] makes each tap a distinct state
/// value, so repeated taps on the same tab still notify listeners.
typedef PersonalTabReselect = ({PersonalTab tab, int sequence});

/// Lets a tab's page react to being re-tapped while it is already showing —
/// e.g. scrolling back to top. The shell emits, pages listen.
@Riverpod(keepAlive: true)
class PersonalTabReselectSignal extends _$PersonalTabReselectSignal {
  @override
  PersonalTabReselect? build() => null;

  void emit(final PersonalTab tab) =>
      state = (tab: tab, sequence: (state?.sequence ?? 0) + 1);
}
