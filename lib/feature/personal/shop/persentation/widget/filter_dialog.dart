import 'package:flutter/material.dart';

class FilterDialog {
  final BuildContext context;
  final String sortBy;
  final bool ascending;
  final RangeValues priceRange;
  final Set<String> selectedTypes;
  final Function(String sortBy, bool ascending, int? minPrice, int? maxPrice, Set<String> selectedTypes) onApply;

  FilterDialog({
    required this.context,
    required this.sortBy,
    required this.ascending,
    required this.priceRange,
    required this.selectedTypes,
    required this.onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _FilterDialogContent(
          sortBy: sortBy,
          ascending: ascending,
          priceRange: priceRange,
          selectedTypes: selectedTypes,
          onApply: onApply,
        );
      },
    );
  }
}

class _FilterDialogContent extends StatefulWidget {
  final String sortBy;
  final bool ascending;
  final RangeValues priceRange;
  final Set<String> selectedTypes;
  final Function(String sortBy, bool ascending, int? minPrice, int? maxPrice, Set<String> selectedTypes) onApply;

  const _FilterDialogContent({
    required this.sortBy,
    required this.ascending,
    required this.priceRange,
    required this.selectedTypes,
    required this.onApply,
  });

  @override
  State<_FilterDialogContent> createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<_FilterDialogContent> {
  late String _sortBy;
  late bool _ascending;
  late RangeValues _priceRange;
  late Set<String> _selectedTypes;
  int? _minPrice;
  int? _maxPrice;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _ascending = widget.ascending;
    _priceRange = widget.priceRange;
    _selectedTypes = Set.from(widget.selectedTypes);
    _minPrice = widget.priceRange.start.round();
    _maxPrice = widget.priceRange.end >= 3000 ? null : widget.priceRange.end.round();
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _sortBy = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _sortBy = 'created_at';
      _ascending = false;
      _minPrice = null;
      _maxPrice = null;
      _priceRange = const RangeValues(0, 3000);
      _selectedTypes.clear();
    });
  }

  void _applyFilters() {
    widget.onApply(_sortBy, _ascending, _minPrice, _maxPrice, _selectedTypes);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '篩選與排序',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 排序選項
            const Text(
              '排序方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildSortOption('價格', 'price'),
            _buildSortOption('建立時間', 'created_at'),
            _buildSortOption('更新時間', 'updated_at'),
            _buildSortOption('試穿次數', 'tryon_count'),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  '遞增排序',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                value: _ascending,
                activeTrackColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _ascending = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // 價格區間
            const Text(
              '價格區間',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_priceRange.start.round()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  _priceRange.end.round() >= 3000
                    ? '\$3000+'
                    : '\$${_priceRange.end.round()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                thumbColor: Theme.of(context).colorScheme.primary,
                overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: RangeSlider(
                values: _priceRange,
                min: 0,
                max: 3000,
                divisions: 100,
                onChanged: (RangeValues values) {
                  setState(() {
                    _priceRange = values;
                    _minPrice = values.start.round();
                    _maxPrice = values.end >= 3000 ? null : values.end.round();
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // 按鈕
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _resetFilters,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            '重置',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _applyFilters,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            '套用',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
