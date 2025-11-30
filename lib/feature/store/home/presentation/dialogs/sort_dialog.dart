import 'package:flutter/material.dart';

class SortOptionsDialog {
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
      builder: (final BuildContext context) {
        return _SortOptionsDialogContent(
          sortBy: sortBy,
          ascending: ascending,
          onSortChange: onSortChange,
          onAscendingChange: onAscendingChange,
        );
      },
    );
  }
  final BuildContext context;
  final String sortBy;
  final bool ascending;
  final Function(String) onSortChange;
  final Function(bool) onAscendingChange;
}

class _SortOptionsDialogContent extends StatefulWidget {
  const _SortOptionsDialogContent({
    required this.sortBy,
    required this.ascending,
    required this.onSortChange,
    required this.onAscendingChange,
  });
  final String sortBy;
  final bool ascending;
  final Function(String) onSortChange;
  final Function(bool) onAscendingChange;

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

  void _handleSortChange(final String newValue) {
    setState(() {
      _sortBy = newValue;
    });
    widget.onSortChange(newValue);
  }

  void _handleAscendingChange(final bool value) {
    setState(() {
      _ascending = value;
    });
    widget.onAscendingChange(value);
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
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

  Widget _buildHeader(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.sort_rounded, color: colorScheme.onPrimary, size: 24),
        ),
        const SizedBox(width: 12),
        Text('排序方式', style: textTheme.titleLarge),
      ],
    );
  }

  Widget _buildSortOptions(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final options = [
      {'label': '價格', 'value': 'price'},
      {'label': '建立時間', 'value': 'created_at'},
      {'label': '更新時間', 'value': 'updated_at'},
      {'label': '試穿次數', 'value': 'tryon_count'},
      {'label': '購買點擊次數', 'value': 'purchase_click_count'},
    ];

    return Column(
      children: options.map((final option) {
        final label = option['label']!;
        final value = option['value']!;
        final isSelected = _sortBy == value;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: InkWell(
            onTap: () => _handleSortChange(value),
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              title: Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              leading: Radio<String>(
                value: value,
                groupValue: _sortBy,
                onChanged: (final val) {
                  if (val != null) {
                    _handleSortChange(val);
                  }
                },
                fillColor: WidgetStateProperty.resolveWith((final states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primary;
                  }
                  return null;
                }),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAscendingSwitch(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          '遞增排序',
          style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
        ),
        value: _ascending,
        activeTrackColor: colorScheme.primary,
        onChanged: _handleAscendingChange,
      ),
    );
  }
}
