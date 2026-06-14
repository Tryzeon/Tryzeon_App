import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class MonthFilterWidget extends HookConsumerWidget {
  const MonthFilterWidget({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filter = ref.watch(storeAnalyticsFilterProvider);
    final now = DateTime.now();
    final isCurrentMonth = filter.year == now.year && filter.month == now.month;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MonthChevronButton(
          icon: Icons.chevron_left_rounded,
          tooltip: '上一個月',
          onPressed: () => _shiftMonth(ref, filter, -1),
        ),
        _MonthLabel(filter: filter),
        _MonthChevronButton(
          icon: Icons.chevron_right_rounded,
          tooltip: '下一個月',
          onPressed: isCurrentMonth ? null : () => _shiftMonth(ref, filter, 1),
        ),
      ],
    );
  }

  void _shiftMonth(
    final WidgetRef ref,
    final ({int year, int month}) filter,
    final int delta,
  ) {
    var newYear = filter.year;
    var newMonth = filter.month + delta;
    if (newMonth < 1) {
      newYear -= 1;
      newMonth = 12;
    } else if (newMonth > 12) {
      newYear += 1;
      newMonth = 1;
    }
    ref.read(storeAnalyticsFilterProvider.notifier).filter = (
      year: newYear,
      month: newMonth,
    );
  }
}

class _MonthChevronButton extends StatelessWidget {
  const _MonthChevronButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(final BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.filter});

  final ({int year, int month}) filter;

  static const List<String> _monthNames = [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        '${filter.year} · ${_monthNames[filter.month - 1]}',
        style: textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary),
      ),
    );
  }
}
