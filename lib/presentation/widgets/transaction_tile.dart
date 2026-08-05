import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../domain/entities/entities.dart';

/// Reusable flat list row for a transaction.
///
/// The row intentionally has no card boundary. Callers can opt into a
/// divider and compact rhythm when it is used in a grouped history list.
class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final bool showWalletName;
  final bool showDivider;
  final bool dense;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showWalletName = true,
    this.showDivider = false,
    this.dense = false,
  });

  // Parse icon string to IconData (fallback to Icons.category).
  IconData _getIcon() {
    const defaultIcon = Icons.category_outlined;

    if (transaction.categoryIcon == null || transaction.categoryIcon!.isEmpty) {
      return defaultIcon;
    }

    final iconName = transaction.categoryIcon!
        .replaceAll('Icons.', '')
        .replaceAll('_outlined', '')
        .toLowerCase();

    switch (iconName) {
      case 'salary':
      case 'work':
        return Icons.work_outlined;
      case 'bonus':
      case 'gift':
        return Icons.card_giftcard_outlined;
      case 'investment':
      case 'trending_up':
        return Icons.trending_up_outlined;
      case 'freelance':
      case 'assignment':
        return Icons.assignment_outlined;
      case 'business':
        return Icons.business_outlined;
      case 'food':
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'shopping':
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'bills':
      case 'receipt':
        return Icons.receipt_outlined;
      case 'health':
      case 'health_and_safety':
        return Icons.health_and_safety_outlined;
      case 'entertainment':
      case 'movie':
        return Icons.movie_outlined;
      case 'education':
      case 'school':
        return Icons.school_outlined;
      case 'communication':
      case 'phone':
        return Icons.phone_outlined;
      default:
        return defaultIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == TransactionType.income;
    final typeColor = isIncome
        ? AppColors.incomeForeground(colorScheme.brightness)
        : AppColors.expenseForeground(colorScheme.brightness);
    final title = transaction.name ?? transaction.categoryName ?? 'Transaksi';
    final metadata = [
      if (transaction.name != null && transaction.categoryName != null)
        transaction.categoryName!,
      if (showWalletName && transaction.walletName != null)
        transaction.walletName!,
      DateFormatter.relative(transaction.transactionDate),
    ].join(' · ');
    final amount =
        '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}';
    final verticalPadding = dense ? AppSpacing.sm : AppSpacing.md;

    return Semantics(
      button: onTap != null,
      label: '$title, $amount',
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.smallBorder,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: dense ? 68 : 76),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: verticalPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: AppRadius.smallBorder,
                          ),
                          child: Icon(
                            _getIcon(),
                            color: typeColor,
                            size: AppIconSize.small + 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              metadata,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 72,
                          maxWidth: 136,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              amount,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: typeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showDivider)
            Divider(height: 1, indent: 52, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }
}
