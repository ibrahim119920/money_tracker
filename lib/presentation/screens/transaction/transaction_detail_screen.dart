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
    final isIncome = transaction.type == TransactionType.income;
    final appBarColor = isIncome ? AppColors.income : AppColors.expense;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(
              '/transactions/form',
              extra: {'type': transaction.type, 'transaction': transaction},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Card - Amount Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [appBarColor, appBarColor.withValues(alpha: 0.8)],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    CurrencyFormatter.format(transaction.amount),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isIncome ? 'Pemasukan' : 'Pengeluaran',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatFullDate(transaction.transactionDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),

            // Detail Rows
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Kategori',
                      value: transaction.categoryName ?? '-',
                    ),
                    const Divider(height: 1, indent: 56),
                    _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Dompet',
                      value: transaction.walletName ?? '-',
                    ),
                    const Divider(height: 1, indent: 56),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Tanggal',
                      value: DateFormatter.formatFullDate(
                        transaction.transactionDate,
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _DetailRow(
                      icon: Icons.notes,
                      label: 'Keterangan',
                      value: transaction.name ?? '-',
                    ),
                    if (transaction.notes != null &&
                        transaction.notes!.isNotEmpty) ...[
                      const Divider(height: 1, indent: 56),
                      _DetailRow(
                        icon: Icons.sticky_note_2,
                        label: 'Catatan',
                        value: transaction.notes ?? '-',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Delete Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Transaksi'),
                onPressed: () => _confirmDelete(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: BorderSide(color: AppColors.expense),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
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
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
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
