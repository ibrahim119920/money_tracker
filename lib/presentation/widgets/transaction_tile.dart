import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../domain/entities/entities.dart';
import '../icons/app_icons.dart';

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
    final isFuture = DateFormatter.isFutureDate(transaction.transactionDate);

    return Semantics(
      button: onTap != null,
      label: '$title, $amount${isFuture ? ', transaksi mendatang' : ''}',
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
                            AppIcons.forCategory(
                              transaction.categoryIcon,
                              categoryName: transaction.categoryName,
                            ),
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
                            if (isFuture) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              const FutureTransactionBadge(),
                            ],
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

/// Visible and accessible status for an income/expense date after today.
class FutureTransactionBadge extends StatelessWidget {
  const FutureTransactionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Transaksi dijadwalkan untuk masa depan',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                'Mendatang',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
