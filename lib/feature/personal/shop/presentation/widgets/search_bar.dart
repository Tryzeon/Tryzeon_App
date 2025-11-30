import 'package:flutter/material.dart';

class ShopSearchBar extends StatefulWidget {
  const ShopSearchBar({super.key, required this.onSearch});
  final Future<void> Function(String query) onSearch;

  @override
  State<ShopSearchBar> createState() => _ShopSearchBarState();
}

class _ShopSearchBarState extends State<ShopSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '搜尋品牌或商品',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearch('');
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (final value) => setState(() {}),
              onSubmitted: widget.onSearch,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onSearch(_controller.text),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Icon(Icons.search, color: colorScheme.onPrimary, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
