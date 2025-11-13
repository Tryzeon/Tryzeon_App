import 'package:flutter/material.dart';
import '../../data/shop_service.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:tryzeon/shared/models/product_model.dart';

class ShopSearchBar extends StatefulWidget {
  final ValueChanged<List<Product>> onSearchResults;
  final VoidCallback onSearchStart;

  const ShopSearchBar({
    super.key,
    required this.onSearchResults,
    required this.onSearchStart,
  });

  @override
  State<ShopSearchBar> createState() => _ShopSearchBarState();
}

class _ShopSearchBarState extends State<ShopSearchBar> {
  final TextEditingController _controller = TextEditingController();

  void _searchProducts(String query) async {
    widget.onSearchStart();
    
    final result = await ShopService.searchProducts(query);
        
    if(!mounted) return;

    if (result.success) {
      widget.onSearchResults(result.products!);
    } else {
      widget.onSearchResults([]);
      TopNotification.show(
        context,
        message: result.errorMessage ?? '搜尋失敗，請稍後再試',
        type: NotificationType.error,
      );
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
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _searchProducts('');
                    setState(() {});
                  },
                ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  _searchProducts(_controller.text);
                },
                tooltip: '搜尋',
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) {
          _searchProducts(value);
        },
      ),
    );
  }
}