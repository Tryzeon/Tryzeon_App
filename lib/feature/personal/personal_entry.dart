import 'package:flutter/material.dart';
import 'chat/persentation/page/chat_page.dart';
import 'community/persentation/pages/community_page.dart';
import 'home/persentation/pages/home_page.dart';
import 'shop/persentation/page/shop_page.dart';
import 'profile/persentation/pages/profile_page.dart';


class PersonalEntry extends StatefulWidget {
  const PersonalEntry({super.key});

  @override
  State<PersonalEntry> createState() => _PersonalEntryState();
}

class _PersonalEntryState extends State<PersonalEntry> {
  int _selectedIndex = 2;

  final List<Widget> _pages = const [
    CommunityPage(),
    ChatPage(),
    HomePage(),
    ShopPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
