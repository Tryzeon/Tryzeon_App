import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

class ProductSearchBar extends HookConsumerWidget {
  const ProductSearchBar({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final query = ref.watch(productQueryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final searchController = useTextEditingController(text: query.searchQuery);
    useListenable(searchController);
    final debounceTimer = useRef<Timer?>(null);

    useEffect(() {
      if (query.searchQuery != searchController.text) {
        searchController.value = TextEditingValue(
          text: query.searchQuery,
          selection: TextSelection.collapsed(offset: query.searchQuery.length),
        );
      }
      return null;
    }, [query.searchQuery]);

    useEffect(() {
      return () => debounceTimer.value?.cancel();
    }, const []);

    void onSearchChanged(final String value) {
      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(const Duration(milliseconds: 300), () {
        ref.read(productQueryProvider.notifier).updateSearch(value);
      });
    }

    return TextField(
      controller: searchController,
      style: textTheme.bodyMedium,
      textInputAction: TextInputAction.search,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: '搜尋商品名稱…',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                onPressed: () {
                  debounceTimer.value?.cancel();
                  searchController.clear();
                  ref.read(productQueryProvider.notifier).updateSearch('');
                },
              ),
      ),
    );
  }
}
