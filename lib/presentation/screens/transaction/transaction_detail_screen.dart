import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final TransactionEntity transaction;

  const TransactionDetailScreen({required this.transaction, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactionAsync = ref.watch(
      transactionDetailProvider(transaction.transactionId),
    );
    final detailTransaction = transactionAsync.valueOrNull ?? transaction;
    final description = detailTransaction.name ?? detailTransaction.notes;
    final hasExtraNotes =
        detailTransaction.notes != null &&
        detailTransaction.notes!.isNotEmpty &&
        detailTransaction.notes != description;

    final isIncome = detailTransaction.type == TransactionType.income;
    final heroBackground = isIncome
        ? colorScheme.incomeContainer
        : colorScheme.expenseContainer;
    final heroForeground = isIncome
        ? colorScheme.onIncomeColor
        : colorScheme.onExpenseColor;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit transaksi',
            onPressed: () => context.push(
              '/transactions/form',
              extra: {'type': transaction.type, 'transaction': transaction},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus transaksi',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Hero Card - Amount Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: heroBackground,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.prominent),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  children: [
                    if (transactionAsync.isLoading)
                      const LinearProgressIndicator(minHeight: 2),

                    Text(
                      CurrencyFormatter.format(detailTransaction.amount),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: heroForeground,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isIncome ? 'Pemasukan' : 'Pengeluaran',
                      style: TextStyle(
                        color: heroForeground.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      DateFormatter.formatFullDate(
                        detailTransaction.transactionDate,
                      ),
                      style: TextStyle(
                        color: heroForeground.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Detail Rows
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: AppRadius.cardBorder,
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.category_outlined,
                        label: 'Kategori',
                        value: detailTransaction.categoryName ?? '-',
                      ),
                      const Divider(height: 1, indent: 56),
                      _DetailRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Dompet',
                        value: detailTransaction.walletName ?? '-',
                      ),
                      const Divider(height: 1, indent: 56),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Tanggal',
                        value: DateFormatter.formatFullDate(
                          detailTransaction.transactionDate,
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _DetailRow(
                        icon: Icons.notes,
                        label: 'Keterangan',
                        value: description ?? '-',
                      ),
                      if (hasExtraNotes) ...[
                        const Divider(height: 1, indent: 56),
                        _DetailRow(
                          icon: Icons.sticky_note_2,
                          label: 'Catatan',
                          value: detailTransaction.notes ?? '-',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Delete Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus Transaksi'),
                  onPressed: () => _confirmDelete(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Transaksi ini akan dihapus dan saldo dompet akan disesuaikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final transactionRepository = ref.read(transactionRepositoryProvider);
          await transactionRepository.deleteTransaction(
            transaction.transactionId,
          );

          // Invalidate caches
          ref.invalidate(transactionsProvider);
          ref.invalidate(walletsProvider);
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(monthlySummaryProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Transaksi berhasil dihapus'),
                backgroundColor: colorScheme.primary,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Gagal menghapus transaksi. Silakan coba lagi.',
                ),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        }
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Detail Row Widget
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
