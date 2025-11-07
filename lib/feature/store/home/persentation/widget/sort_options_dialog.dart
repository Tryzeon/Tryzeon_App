import 'package:flutter/material.dart';

class SortOptionsDialog {
  final BuildContext context;
  final String sortBy;
  final bool ascending;
  final Function(String) onSortChange;
  final Function(bool) onAscendingChange;

  SortOptionsDialog({
    required this.context,
    required this.sortBy,
    required this.ascending,
    required this.onSortChange,
    required this.onAscendingChange,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _SortOptionsDialogContent(
          sortBy: sortBy,
          ascending: ascending,
          onSortChange: onSortChange,
          onAscendingChange: onAscendingChange,
        );
      },
    );
  }
}

class _SortOptionsDialogContent extends StatefulWidget {
  final String sortBy;
  final bool ascending;
  final Function(String) onSortChange;
  final Function(bool) onAscendingChange;

  const _SortOptionsDialogContent({
    required this.sortBy,
    required this.ascending,
    required this.onSortChange,
    required this.onAscendingChange,
  });

  @override
  State<_SortOptionsDialogContent> createState() => _SortOptionsDialogContentState();
}

class _SortOptionsDialogContentState extends State<_SortOptionsDialogContent> {
  late String _sortBy;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _ascending = widget.ascending;
  }

  void _handleSortChange(String newValue) {
    setState(() {
      _sortBy = newValue;
    });
    widget.onSortChange(newValue);
  }

  void _handleAscendingChange(bool value) {
    setState(() {
      _ascending = value;
    });
    widget.onAscendingChange(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSortOptions(context),
            const SizedBox(height: 16),
            _buildAscendingSwitch(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
            Icons.sort_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '排序方式',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    final options = [
      {'label': '價格', 'value': 'price'},
      {'label': '建立時間', 'value': 'created_at'},
      {'label': '更新時間', 'value': 'updated_at'},
      {'label': '試穿次數', 'value': 'tryon_count'},
      {'label': '購買點擊次數', 'value': 'purchase_click_count'},
    ];

    return RadioGroup<String>(
      groupValue: _sortBy,
      onChanged: (String? newValue) {
        if (newValue != null) {
          _handleSortChange(newValue);
        }
      },
      child: Column(
        children: options.map((option) {
          final label = option['label']!;
          final value = option['value']!;
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
              onTap: () => _handleSortChange(value),
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                  ),
                ),
                leading: Radio<String>(
                  value: value,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return null;
                  }),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAscendingSwitch(BuildContext context) {
    return Container(
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
        onChanged: _handleAscendingChange,
      ),
    );
  }
}
