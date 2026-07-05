import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _DashboardBootstrap(),
        _DashboardScaffold(
          onAddTransaction: () => _showAddTransactionSheet(context),
        ),
        const _TutorialOverlay(),
      ],
    );
  }
}

class _DashboardBootstrap extends ConsumerWidget {
  const _DashboardBootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(defaultCashbookProvider);
    return const SizedBox.shrink();
  }
}

class _DashboardScaffold extends ConsumerWidget {
  final VoidCallback onAddTransaction;

  const _DashboardScaffold({required this.onAddTransaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: const _CashbookSwitcher(),
        actions: const [_DashboardAvatar()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletsProvider);
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(monthlySummaryProvider);
          await Future.wait([
            ref
                .read(walletsProvider.future)
                .catchError((_) => <WalletEntity>[]),
            ref.read(totalBalanceProvider.future).catchError((_) => 0),
            ref
                .read(monthlySummaryProvider.future)
                .catchError((_) => <String, int>{}),
          ]);
        },
        child: const _DashboardBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Transaksi Baru'),
      ),
      bottomNavigationBar: const _DashboardBottomNav(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _TotalBalanceCard(),
          SizedBox(height: 16),
          _MonthlySection(),
          SizedBox(height: 8),
          _WalletSection(),
        ],
      ),
    );
  }
}

class _DashboardAvatar extends ConsumerWidget {
  const _DashboardAvatar();

  String _initial(String? displayName) {
    final trimmed = displayName?.trim();
    if (trimmed == null || trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return currentUserAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            _initial(user?.displayName),
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.push('/transactions');
            break;
          case 2:
            context.push('/report/monthly');
            break;
          case 3:
            context.push('/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Transaksi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Laporan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Pengaturan',
        ),
      ],
    );
  }
}

void _showAddTransactionSheet(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Tambah Transaksi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.arrow_downward,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Pemasukan'),
            subtitle: const Text('Catat uang masuk'),
            onTap: () {
              Navigator.pop(context);
              context.push(
                '/transactions/form',
                extra: {'type': TransactionType.income, 'transaction': null},
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.errorContainer,
              child: Icon(
                Icons.arrow_upward,
                color: colorScheme.onErrorContainer,
              ),
            ),
            title: const Text('Pengeluaran'),
            subtitle: const Text('Catat uang keluar'),
            onTap: () {
              Navigator.pop(context);
              context.push(
                '/transactions/form',
                extra: {'type': TransactionType.expense, 'transaction': null},
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.swap_horiz,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            title: const Text('Transfer'),
            subtitle: const Text('Pindahkan saldo antar dompet'),
            onTap: () {
              Navigator.pop(context);
              context.push('/transfer');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Cashbook Switcher (AppBar title)
// ---------------------------------------------------------------------------

class _CashbookSwitcher extends ConsumerWidget {
  const _CashbookSwitcher();

  void _showBottomSheet(
    BuildContext context,
    WidgetRef ref,
    CashbookEntity? activeCashbook,
    List<CashbookEntity> cashbooks,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Pilih Buku Kas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...cashbooks.map(
              (cb) => ListTile(
                leading: Icon(
                  Icons.book_outlined,
                  color: cb.cashbookId == activeCashbook?.cashbookId
                      ? colorScheme.primary
                      : null,
                ),
                title: Text(cb.cashbookName),
                trailing: cb.isDefault
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                selected: cb.cashbookId == activeCashbook?.cashbookId,
                selectedColor: colorScheme.primary,
                onTap: () {
                  ref.read(activeCashbookProvider.notifier).state = cb;
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Kelola Buku Kas',
                style: TextStyle(color: AppColors.primary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/cashbooks');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCashbook = ref.watch(activeCashbookProvider);
    final cashbooksAsync = ref.watch(cashbooksProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        cashbooksAsync.whenData(
          (cashbooks) =>
              _showBottomSheet(context, ref, activeCashbook, cashbooks),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activeCashbook?.cashbookName ?? 'Pilih Buku Kas',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total Balance Card
// ---------------------------------------------------------------------------

class _TotalBalanceCard extends ConsumerWidget {
  const _TotalBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalBalanceAsync = ref.watch(totalBalanceProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.primaryContainer, colorScheme.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Saldo',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: totalBalanceAsync.when(
              loading: () =>
                  const _TotalBalanceLoading(key: ValueKey('loading')),
              error: (_, __) => const Text(
                'â€”',
                key: ValueKey('error'),
                style: TextStyle(color: Colors.white, fontSize: 28),
              ),
              data: (total) => Text(
                CurrencyFormatter.format(total),
                key: ValueKey(total),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBalanceLoading extends StatelessWidget {
  const _TotalBalanceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      width: 140,
      alignment: Alignment.centerLeft,
      child: Container(
        width: 120,
        height: 24,
        decoration: BoxDecoration(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly Summary Section
// ---------------------------------------------------------------------------

class _MonthlySection extends ConsumerWidget {
  const _MonthlySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan ${DateFormatter.formatMonthYear(selectedMonth)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: summaryAsync.when(
              loading: () =>
                  const _MonthlySummaryLoading(key: ValueKey('loading')),
              error: (_, __) =>
                  const SizedBox(height: 80, key: ValueKey('error')),
              data: (summary) {
                final income = summary['income'] ?? 0;
                final expense = summary['expense'] ?? 0;
                return Row(
                  key: ValueKey('$income:$expense'),
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Pemasukan',
                        amount: income,
                        icon: Icons.arrow_downward,
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Pengeluaran',
                        amount: expense,
                        icon: Icons.arrow_upward,
                        color: colorScheme.secondary,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySummaryLoading extends StatelessWidget {
  const _MonthlySummaryLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SummaryTilePlaceholder()),
        SizedBox(width: 12),
        Expanded(child: _SummaryTilePlaceholder()),
      ],
    );
  }
}

class _SummaryTilePlaceholder extends StatelessWidget {
  const _SummaryTilePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 64, height: 10, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Container(width: 88, height: 16, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet Section
// ---------------------------------------------------------------------------

class _WalletSection extends ConsumerWidget {
  const _WalletSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final walletsAsync = ref.watch(walletsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dompet', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => context.push('/wallets'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: walletsAsync.when(
            loading: () => const Padding(
              key: ValueKey('loading'),
              padding: EdgeInsets.all(16),
              child: _WalletLoadingStrip(),
            ),
            error: (_, __) => Padding(
              key: const ValueKey('error'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Gagal memuat dompet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            data: (wallets) {
              if (wallets.isEmpty) {
                return Padding(
                  key: const ValueKey('empty'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 40,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada dompet',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/wallets'),
                              child: const Text('Tambah Dompet'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SizedBox(
                key: ValueKey(wallets.length),
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: wallets.length,
                  itemBuilder: (_, index) =>
                      _WalletCard(wallet: wallets[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WalletLoadingStrip extends StatelessWidget {
  const _WalletLoadingStrip();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 160,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  color: colorScheme.outlineVariant,
                ),
                const Spacer(),
                Container(
                  width: 96,
                  height: 12,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 72,
                  height: 10,
                  color: colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet Card (horizontal scroll item)
// ---------------------------------------------------------------------------

class _WalletCard extends StatelessWidget {
  final WalletEntity wallet;

  const _WalletCard({required this.wallet});

  Color _cardColor(BuildContext context, WalletType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case WalletType.cash:
        return isDark ? AppColors.darkMintContainer : AppColors.mint;
      case WalletType.bankAcc:
        return isDark ? AppColors.darkPrimaryContainer : AppColors.primary;
      case WalletType.eWallet:
        return isDark ? AppColors.darkLavenderContainer : AppColors.lavender;
    }
  }

  IconData _cardIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.payments_outlined;
      case WalletType.bankAcc:
        return Icons.account_balance_outlined;
      case WalletType.eWallet:
        return Icons.phone_android_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _cardColor(context, wallet.type);
    final foregroundColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: () => context.push('/wallets/detail', extra: wallet),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.82)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_cardIcon(wallet.type), color: foregroundColor, size: 24),
            const Spacer(),
            Text(
              wallet.walletName,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(wallet.currentBalance),
              style: TextStyle(color: foregroundColor, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tutorial Overlay - Mandatory onboarding guide (fullscreen)
// ---------------------------------------------------------------------------

class _TutorialOverlay extends ConsumerWidget {
  const _TutorialOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashbooksAsync = ref.watch(cashbooksProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final activeCashbook = ref.watch(activeCashbookProvider);

    // Jangan tampilkan overlay saat data masih loading (mencegah false positive)
    if (cashbooksAsync.isLoading) return const SizedBox.shrink();

    final bool step1 =
        cashbooksAsync.whenOrNull(data: (c) => c.isEmpty) ?? false;

    // step2 hanya valid jika activeCashbook sudah di-set (bukan null-cashbook result)
    final bool step2 =
        !step1 &&
        activeCashbook != null &&
        (walletsAsync.whenOrNull(data: (w) => w.isEmpty) ?? false);

    if (!step1 && !step2) return const SizedBox.shrink();

    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Color(0x80000000)),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _TutorialCard(
                step: step1 ? 1 : 2,
                onAction: () async {
                  if (step1) {
                    await context.push('/cashbooks/form');
                    // Ensure active cashbook is set for step 2
                    ref.invalidate(defaultCashbookProvider);
                  } else {
                    context.push('/wallets/form');
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tutorial Card
// ---------------------------------------------------------------------------

class _TutorialCard extends StatelessWidget {
  final int step;
  final VoidCallback onAction;

  const _TutorialCard({required this.step, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isStep1 = step == 1;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                Text(
                  'Tutorial Wajib',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _StepDot(active: true, label: '1'),
                const SizedBox(width: 6),
                _StepDot(active: !isStep1, label: '2'),
              ],
            ),
            const SizedBox(height: 20),
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isStep1
                    ? Icons.menu_book_rounded
                    : Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isStep1
                  ? 'Langkah 1 dari 2: Buat Buku Kas'
                  : 'Langkah 2 dari 2: Buat Dompet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isStep1
                  ? 'Buku Kas adalah tempat untuk mengelompokkan transaksi dan dompet Anda. Mulai dengan membuat buku kas pertama.'
                  : 'Dompet mewakili akun keuangan Anda (tunai, rekening bank, atau e-wallet). Tambahkan dompet pertama Anda.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(isStep1 ? 'Buat Buku Kas' : 'Buat Dompet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Dot Indicator
// ---------------------------------------------------------------------------

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;

  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
