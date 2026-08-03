import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../data/models/models.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/money_metric.dart';
import '../../widgets/transaction_tile.dart';

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

  Color _typeAccent(ColorScheme colorScheme, WalletType type) {
    switch (type) {
      case WalletType.cash:
        return colorScheme.successColor;
      case WalletType.bankAcc:
        return colorScheme.primary;
      case WalletType.eWallet:
        return colorScheme.transferColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    final heroBackground = colorScheme.primaryContainer;
    final heroForeground = colorScheme.onPrimaryContainer;
    final typeAccent = _typeAccent(colorScheme, wallet.type);

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
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit dompet',
            onPressed: () => context.push('/wallets/form', extra: wallet),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // SECTION 1 — Continuous wallet hero with a calm filled surface
              // ----------------------------------------------------------------
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: heroBackground,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.prominent),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.xxs,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: icon (32px) + tipe label
                    Row(
                      children: [
                        Icon(
                          _getIcon(wallet.type),
                          color: typeAccent,
                          size: AppIconSize.large,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _getTypeLabel(wallet.type),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: heroForeground.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // wallet_name
                    Text(
                      wallet.walletName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: heroForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // bank_name + account_number jika tidak null
                    if (wallet.bankName != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        [
                          wallet.bankName,
                          wallet.accountNumber,
                        ].whereType<String>().join(' • '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: heroForeground.withValues(alpha: 0.85),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Label "Saldo Saat Ini"
                    Text(
                      'Saldo Saat Ini',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: heroForeground.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),

                    // current_balance
                    Text(
                      CurrencyFormatter.format(wallet.currentBalance),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: heroForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ----------------------------------------------------------------
              // SECTION 2 — Ringkasan Bulan Ini
              // ----------------------------------------------------------------
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: AppSectionHeader(title: 'Ringkasan Bulan Ini'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: summaryAsync.when(
                    loading: () =>
                        const _WalletSummaryLoading(key: ValueKey('loading')),
                    error: (_, _) =>
                        const SizedBox(height: 80, key: ValueKey('error')),
                    data: (summary) => _WalletSummarySurface(
                      key: ValueKey(
                        '${summary['income'] ?? 0}:${summary['expense'] ?? 0}',
                      ),
                      income: summary['income'] ?? 0,
                      expense: summary['expense'] ?? 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ----------------------------------------------------------------
              // SECTION 3 — Riwayat Transaksi
              // ----------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: AppSectionHeader(
                  title: 'Riwayat Transaksi',
                  actionLabel: 'Lihat Semua',
                  onAction: () => context.push('/transactions'),
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: transactionsAsync.when(
                  loading: () => const Padding(
                    key: ValueKey('loading'),
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: _WalletTransactionsLoading(),
                  ),
                  error: (_, __) => Padding(
                    key: const ValueKey('error'),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Gagal memuat transaksi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Padding(
                        key: const ValueKey('empty'),
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
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada transaksi',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Container(
                      key: ValueKey(transactions.length),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: AppRadius.cardBorder,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (_, index) => TransactionTile(
                          transaction: transactions[index],
                          dense: true,
                          showWalletName: false,
                          showDivider: index < transactions.length - 1,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _WalletSummaryLoading extends StatelessWidget {
  const _WalletSummaryLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
      ),
      child: const Row(
        children: [
          Expanded(child: _WalletSummaryMetricPlaceholder()),
          _WalletSummaryVerticalDivider(),
          Expanded(child: _WalletSummaryMetricPlaceholder()),
        ],
      ),
    );
  }
}

class _WalletSummarySurface extends StatelessWidget {
  final int income;
  final int expense;

  const _WalletSummarySurface({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: MoneyMetric(
              label: 'Pemasukan',
              value: CurrencyFormatter.format(income),
              type: MoneyMetricType.income,
              compact: true,
            ),
          ),
          const _WalletSummaryVerticalDivider(),
          Expanded(
            child: MoneyMetric(
              label: 'Pengeluaran',
              value: CurrencyFormatter.format(expense),
              type: MoneyMetricType.expense,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSummaryVerticalDivider extends StatelessWidget {
  const _WalletSummaryVerticalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: AppSpacing.md,
      child: VerticalDivider(
        thickness: AppBorder.subtleWidth,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _WalletSummaryMetricPlaceholder extends StatelessWidget {
  const _WalletSummaryMetricPlaceholder();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 64, height: 10, color: color),
        const SizedBox(height: AppSpacing.xs),
        Container(width: 100, height: 16, color: color),
      ],
    );
  }
}

class _WalletTransactionsLoading extends StatelessWidget {
  const _WalletTransactionsLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 2 ? 0 : AppSpacing.xs),
            child: const ListTile(
              leading: _WalletTransactionLeadingPlaceholder(),
              title: _WalletLinePlaceholder(width: 120),
              subtitle: _WalletLinePlaceholder(width: 160, height: 10),
              trailing: _WalletLinePlaceholder(width: 72, height: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletTransactionLeadingPlaceholder extends StatelessWidget {
  const _WalletTransactionLeadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          borderRadius: AppRadius.smallBorder,
        ),
      ),
    );
  }
}

class _WalletLinePlaceholder extends StatelessWidget {
  final double width;
  final double height;

  const _WalletLinePlaceholder({required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        borderRadius: AppRadius.smallBorder,
      ),
    );
  }
}
