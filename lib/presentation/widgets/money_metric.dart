import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';

/// Semantic presentation tones for a monetary summary.
enum MoneyMetricType { neutral, income, expense, transfer }

/// Displays an already formatted monetary value without owning money logic.
class MoneyMetric extends StatelessWidget {
  const MoneyMetric({
    required this.label,
    required this.value,
    this.type = MoneyMetricType.neutral,
    this.color,
    this.compact = false,
    super.key,
  });

  final String label;
  final String value;
  final MoneyMetricType type;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final valueColor = color ?? _semanticColor(colorScheme);
    final labelStyle = theme.textTheme.labelMedium;
    final valueStyle =
        (compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)
            ?.copyWith(color: valueColor, fontWeight: FontWeight.w600);

    return Semantics(
      container: true,
      label: '$label, $value',
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: valueStyle,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
              ],
            ),
    );
  }

  Color _semanticColor(ColorScheme colorScheme) {
    return switch (type) {
      MoneyMetricType.income => colorScheme.incomeColor,
      MoneyMetricType.expense => colorScheme.expenseColor,
      MoneyMetricType.transfer => colorScheme.transferColor,
      MoneyMetricType.neutral => colorScheme.onSurface,
    };
  }
}
