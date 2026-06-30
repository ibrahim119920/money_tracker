import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Always 0 (Dashboard). Nav bar hanya ada di DashboardScreen;
  // halaman lain di-push ke atas stack sehingga bar tidak terlihat.
  // Tidak boleh diubah agar highlight tetap di Dashboard saat kembali.
  final int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Auto-load default cashbook & set as active
    ref.watch(defaultCashbookProvider);

    final cashbooksAsync = ref.watch(cashbooksProvider);
    final activeCashbook = ref.watch(activeCashbookProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: _CashbookSwitcher(
              activeCashbook: activeCashbook,
              cashbooksAsync: cashbooksAsync,
              ref: ref,
            ),
            actions: [
              currentUserAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(walletsProvider);
              ref.invalidate(totalBalanceProvider);
              ref.invalidate(monthlySummaryProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total balance card (AppBar background extends)
                  _TotalBalanceCard(totalBalanceAsync: totalBalanceAsync),

                  const SizedBox(height: 16),

                  // Ringkasan bulan ini
                  _MonthlySection(),

                  const SizedBox(height: 8),

                  // Daftar dompet
                  _WalletSection(walletsAsync: walletsAsync),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTransactionSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Transaksi Baru'),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedNavIndex,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              switch (index) {
                case 0:
                  // Dashboard - already here
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
          ),
        ),
        const _TutorialOverlay(),
      ],
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
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
            // Income Option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.income,
                child: const Icon(Icons.arrow_downward, color: Colors.white),
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
            // Expense Option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.expense,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
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
            // Transfer Option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.transfer,
                child: const Icon(Icons.swap_horiz, color: Colors.white),
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
}

// ---------------------------------------------------------------------------
// Cashbook Switcher (AppBar title)
// ---------------------------------------------------------------------------

class _CashbookSwitcher extends StatelessWidget {
  final CashbookEntity? activeCashbook;
  final AsyncValue<List<CashbookEntity>> cashbooksAsync;
  final WidgetRef ref;

  const _CashbookSwitcher({
    required this.activeCashbook,
    required this.cashbooksAsync,
    required this.ref,
  });

  void _showBottomSheet(BuildContext context, List<CashbookEntity> cashbooks) {
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
                      ? AppColors.primary
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
                          color: AppColors.primary.withValues(alpha: 0.12),
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
                selectedColor: AppColors.primary,
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        cashbooksAsync.whenData(
          (cashbooks) => _showBottomSheet(context, cashbooks),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activeCashbook?.cashbookName ?? 'Pilih Buku Kas',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total Balance Card
// ---------------------------------------------------------------------------

class _TotalBalanceCard extends StatelessWidget {
  final AsyncValue<int> totalBalanceAsync;

  const _TotalBalanceCard({required this.totalBalanceAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          totalBalanceAsync.when(
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (_, __) => const Text(
              'â€”',
              style: TextStyle(color: Colors.white, fontSize: 28),
            ),
            data: (total) => Text(
              CurrencyFormatter.format(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          summaryAsync.when(
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
                    child: _SummaryTile(
                      label: 'Pemasukan',
                      amount: income,
                      icon: Icons.arrow_downward,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
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

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
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

// ---------------------------------------------------------------------------
// Wallet Section
// ---------------------------------------------------------------------------

class _WalletSection extends StatelessWidget {
  final AsyncValue<List<WalletEntity>> walletsAsync;

  const _WalletSection({required this.walletsAsync});

  @override
  Widget build(BuildContext context) {
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
        walletsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Gagal memuat dompet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          data: (wallets) {
            if (wallets.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 40,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada dompet',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
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
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: wallets.length,
                itemBuilder: (_, index) => _WalletCard(wallet: wallets[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet Card (horizontal scroll item)
// ---------------------------------------------------------------------------

class _WalletCard extends StatelessWidget {
  final WalletEntity wallet;

  const _WalletCard({required this.wallet});

  Color _cardColor(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return AppColors.success;
      case WalletType.bankAcc:
        return AppColors.primary;
      case WalletType.eWallet:
        return AppColors.transfer;
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
    final color = _cardColor(wallet.type);

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
            colors: [color, color.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_cardIcon(wallet.type), color: Colors.white, size: 24),
            const Spacer(),
            Text(
              wallet.walletName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(wallet.currentBalance),
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
