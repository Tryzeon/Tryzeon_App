import 'package:flutter/material.dart';
import 'chat/persentation/page/chat_page.dart';
import 'community/persentation/pages/community_page.dart';
import 'home/persentation/pages/home_page.dart';
import 'shop/persentation/page/shop_page.dart';
import 'profile/persentation/pages/profile_page.dart';


class PersonalEntry extends StatefulWidget {
  const PersonalEntry({super.key});

  @override
  State<PersonalEntry> createState() => PersonalEntryState();

  static PersonalEntryState? of(BuildContext context) {
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
      const ChatPage(),
      HomePage(key: _homePageKey),
      const ShopPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> startTryonFromProduct(String productImageUrl) async {
    // 切換到 HomePage
    setState(() {
      _selectedIndex = 2;
    });

    // 呼叫 HomePage 的試穿方法
    await _homePageKey.currentState?.startTryonFromProduct(productImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '社群'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '聊天'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '商城'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '個人'),
        ],
      ),
    );
  }
}
