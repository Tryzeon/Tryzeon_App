import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/shared/services/auth_service.dart';

import 'chat/persentation/page/chat_page.dart';
import 'community/persentation/pages/community_page.dart';
import 'home/persentation/pages/home_page.dart';
import 'personal/personal_page.dart';
import 'shop/persentation/page/shop_page.dart';

class PersonalEntry extends StatefulWidget {
  const PersonalEntry({super.key});

  @override
  State<PersonalEntry> createState() => PersonalEntryState();

  static PersonalEntryState? of(final BuildContext context) {
    return context.findAncestorStateOfType<PersonalEntryState>();
  }
}

class PersonalEntryState extends State<PersonalEntry> {
  int _selectedIndex = 2;
  late final List<Widget> _pages;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      const CommunityPage(),
      const ShopPage(),
      HomePage(key: _homePageKey),
      const ChatPage(),
      const PersonalPage(),
    ];

    AuthService.saveLastLoginType(UserType.personal);
  }

  void _onItemTapped(final int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> tryOnFromStorage(final String storagePath) async {
    // 切換到 HomePage
    setState(() {
      _selectedIndex = 2;
    });

    // 呼叫 HomePage 的試穿方法
    await _homePageKey.currentState?.tryOnFromStorage(storagePath);
  }

  @override
  Widget build(final BuildContext context) {
    return AdaptiveScaffold(
      minimizeBehavior: TabBarMinimizeBehavior.never,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        useNativeBottomBar: true,
        items: [
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? 'person.3'
                : PlatformInfo.isIOS
                ? CupertinoIcons.group
                : Icons.group_outlined,
            label: '社群',
          ),
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? 'cart'
                : PlatformInfo.isIOS
                ? CupertinoIcons.cart
                : Icons.shopping_cart_outlined,
            label: '試衣間',
          ),
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? 'house'
                : PlatformInfo.isIOS
                ? CupertinoIcons.house
                : Icons.home_outlined,
            label: '首頁',
          ),
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? 'message'
                : PlatformInfo.isIOS
                ? CupertinoIcons.chat_bubble
                : Icons.chat_outlined,
            label: '聊天',
          ),
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? 'person'
                : PlatformInfo.isIOS
                ? CupertinoIcons.person
                : Icons.person_outline,
            label: '個人',
          ),
        ],
      ),
    );
  }
}
