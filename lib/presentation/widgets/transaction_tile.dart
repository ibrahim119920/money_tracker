import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../domain/entities/entities.dart';

/// Reusable widget untuk menampilkan satu item transaksi
/// Digunakan di TransactionListScreen, TransactionDetailScreen, WalletDetailScreen, Dashboard
class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final bool showWalletName;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showWalletName = true,
  });

  // Determine color based on transaction type
  Color _getTypeColor() {
    return transaction.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
  }

  // Parse icon string to IconData (fallback to Icons.category)
  IconData _getIcon() {
    // Default category icon
    const defaultIcon = Icons.category_outlined;

    if (transaction.categoryIcon == null || transaction.categoryIcon!.isEmpty) {
      return defaultIcon;
    }

    // Try to parse common icon names from Material Icons
    // Format expected: "Icons.shopping_bag" or just "shopping_bag"
    final iconName = transaction.categoryIcon!
        .replaceAll('Icons.', '')
        .replaceAll('_outlined', '')
        .toLowerCase();

    // Map common transaction category icons
    switch (iconName) {
      // Income icons
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

      // Expense icons
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
    final isIncome = transaction.type == TransactionType.income;
    final typeColor = _getTypeColor();
    final title = transaction.name ?? transaction.categoryName ?? 'Transaksi';

    // Build subtitle: date [· wallet name]
    final subtitleParts = [
      DateFormatter.relative(transaction.transactionDate),
      if (showWalletName && transaction.walletName != null)
        transaction.walletName!,
    ];
    final subtitle = subtitleParts.join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar by transaction type
              Container(width: 4, color: typeColor),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Leading: Icon container (40x40)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getIcon(), color: typeColor, size: 22),
                      ),

                      const SizedBox(width: 12),

                      // Body: Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Trailing: Amount and category name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (transaction.categoryName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              transaction.categoryName!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
