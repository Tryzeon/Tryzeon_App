import 'package:flutter/material.dart';
import '../../data/shop_service.dart';

class ShopSearchBar extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final ValueChanged<List<Map<String, dynamic>>> onSearchResults;
  final VoidCallback onSearchStart;

  const ShopSearchBar({
    super.key,
    required this.products,
    required this.onSearchResults,
    required this.onSearchStart,
  });

  @override
  State<ShopSearchBar> createState() => _ShopSearchBarState();
}

class _ShopSearchBarState extends State<ShopSearchBar> {
  final TextEditingController _controller = TextEditingController();
  String? _currentSearchQuery;

  void _searchProducts(String query) async {
    // 儲存當前的搜尋查詢
    _currentSearchQuery = query;
    
    if (query.trim().isEmpty) {
      widget.onSearchResults(widget.products);
      return;
    }

    widget.onSearchStart();

    // 儲存當前查詢的參考，用於檢查是否為最新的搜尋
    final currentQuery = query;
    
    final searchResults = await ShopService.searchProducts(query);
    
    // 只有當這是最新的搜尋請求時才更新結果
    if (currentQuery == _currentSearchQuery && mounted) {
      widget.onSearchResults(searchResults);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: '搜尋品牌或商品',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _searchProducts('');
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          _searchProducts(value);
        },
      ),
    );
  }
}