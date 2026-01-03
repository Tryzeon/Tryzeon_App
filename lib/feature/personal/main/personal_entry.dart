import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../chat/presentation/pages/chat_page.dart';
import '../community/presentation/pages/community_page.dart';
import '../home/presentation/pages/home_page.dart';
import '../shop/presentation/pages/shop_page.dart';
import '../wardrobe/presentation/pages/wardrobe_page.dart';

class PersonalEntryScope extends InheritedWidget {
  const PersonalEntryScope({
    super.key,
    required this.tryOnFromStorage,
    required super.child,
  });

  final Future<void> Function(String clothesPath) tryOnFromStorage;

  static PersonalEntryScope? of(final BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PersonalEntryScope>();
  }

  @override
  bool updateShouldNotify(final PersonalEntryScope oldWidget) {
    return oldWidget.tryOnFromStorage != tryOnFromStorage;
  }
}

class PersonalEntry extends HookConsumerWidget {
  const PersonalEntry({super.key});

  static PersonalEntryScope? of(final BuildContext context) {
    return PersonalEntryScope.of(context);
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedIndex = useState(2);
    final homePageController = useMemoized(HomePageController.new);

    // Dispose controller when widget is disposed
    useEffect(() {
      return homePageController.dispose;
    }, [homePageController]);

    final pages = useMemoized(
      () => [
        const CommunityPage(),
        const ShopPage(),
        HomePage(controller: homePageController),
        const ChatPage(),
        const PersonalPage(),
      ],
      [homePageController], // Recreate pages if controller changes (unlikely)
    );

    Future<void> tryOnFromStorage(final String clothesPath) async {
      // 切換到 HomePage
      selectedIndex.value = 2;

      // 呼叫 HomePage 的試穿方法
      if (homePageController.tryOnFromStorage != null) {
        await homePageController.tryOnFromStorage!(clothesPath);
      }
    }

    void onItemTapped(final int index) {
      selectedIndex.value = index;
    }

    return PersonalEntryScope(
      tryOnFromStorage: tryOnFromStorage,
      child: AdaptiveScaffold(
        minimizeBehavior: TabBarMinimizeBehavior.never,
        body: IndexedStack(index: selectedIndex.value, children: pages),
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          selectedIndex: selectedIndex.value,
          onTap: onItemTapped,
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
      ),
    );
  }
}
