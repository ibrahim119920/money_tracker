import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../data/models/models.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

// ---------------------------------------------------------------------------
// File-scoped family providers (avoid anonymous providers in build)
// ---------------------------------------------------------------------------

/// Monthly summary per wallet (income & expense untuk bulan ini)
final _walletMonthlySummaryProvider =
    FutureProvider.family<
      Map<String, int>,
      ({String walletId, int year, int month})
    >((ref, params) async {
      final repository = ref.watch(walletRepositoryProvider);
      return repository.getMonthlySummary(
        walletId: params.walletId,
        month: DateTime(params.year, params.month),
      );
    });

/// Transaksi per wallet bulan ini (max 20, urut terbaru)
final _walletTransactionsProvider =
    FutureProvider.family<List<TransactionEntity>, String>((
      ref,
      walletId,
    ) async {
      final client = ref.watch(supabaseClientProvider);
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      try {
        final response = await client
            .from('transactions')
            .select('*, categories(category_name, icon, color)')
            .eq('wallet_id', walletId)
            .eq('is_deleted', false)
            .gte('transaction_date', monthStart.toIso8601String().split('T')[0])
            .order('transaction_date', ascending: false)
            .limit(20);
        return (response as List)
            .map((e) => TransactionModel.fromJson(e).toEntity())
            .toList();
      } catch (_) {
        return [];
      }
    });

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Detail screen untuk satu dompet
class WalletDetailScreen extends ConsumerWidget {
  final WalletEntity wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  // Gradient per tipe: cash=hijau, bank_acc=biru, ewallet=ungu
  List<Color> _gradientColors(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return [AppColors.success, const Color(0xFF2E7D32)];
      case WalletType.bankAcc:
        return [AppColors.primary, AppColors.primaryDark];
      case WalletType.eWallet:
        return [AppColors.transfer, const Color(0xFF6A1B9A)];
    }
  }

  IconData _getIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.payments_outlined;
      case WalletType.bankAcc:
        return Icons.account_balance_outlined;
      case WalletType.eWallet:
        return Icons.phone_android_outlined;
    }
  }

  String _getTypeLabel(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return 'Tunai';
      case WalletType.bankAcc:
        return 'Rekening Bank';
      case WalletType.eWallet:
        return 'Dompet Digital';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final gradients = _gradientColors(wallet.type);

    final summaryAsync = ref.watch(
      _walletMonthlySummaryProvider((
        walletId: wallet.walletId,
        year: now.year,
        month: now.month,
      )),
    );
    final transactionsAsync = ref.watch(
      _walletTransactionsProvider(wallet.walletId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Dompet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradients,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit dompet',
            onPressed: () => context.push('/wallets/form', extra: wallet),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // SECTION 1 — Header Card (full width, rounded bottom, gradient)
            // ----------------------------------------------------------------
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradients,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: icon (32px) + tipe label
                  Row(
                    children: [
                      Icon(
                        _getIcon(wallet.type),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getTypeLabel(wallet.type),
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // wallet_name
                  Text(
                    wallet.walletName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // bank_name + account_number jika tidak null
                  if (wallet.bankName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        wallet.bankName,
                        wallet.accountNumber,
                      ].whereType<String>().join(' • '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Label "Saldo Saat Ini"
                  Text(
                    'Saldo Saat Ini',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // current_balance
                  Text(
                    CurrencyFormatter.format(wallet.currentBalance),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------------------
            // SECTION 2 — Ringkasan Bulan Ini
            // ----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Ringkasan Bulan Ini',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: summaryAsync.when(
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(height: 80),
                data: (summary) {
                  final income = summary['income'] ?? 0;
                  final expense = summary['expense'] ?? 0;
                  return Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Pemasukan',
                          amount: income,
                          icon: Icons.arrow_downward,
                          color: AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Pengeluaran',
                          amount: expense,
                          icon: Icons.arrow_upward,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // SECTION 3 — Riwayat Transaksi
            // ----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Transaksi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: navigate ke halaman semua transaksi dengan filter walletId
                    },
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
            ),

            transactionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat transaksi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada transaksi',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: transactions.length,
                  itemBuilder: (_, index) {
                    final tx = transactions[index];
                    final isIncome = tx.type == TransactionType.income;
                    final amountColor = isIncome
                        ? AppColors.income
                        : AppColors.expense;
                    final title = tx.name ?? tx.categoryName ?? 'Transaksi';
                    final subtitleParts = [
                      DateFormatter.relative(tx.transactionDate),
                      if (tx.categoryName != null) tx.categoryName!,
                    ];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: amountColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: amountColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          subtitleParts.join(' · '),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
