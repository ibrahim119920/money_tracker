import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../icons/app_icons.dart';
import '../../providers/providers.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/money_metric.dart';

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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const _CashbookSwitcher(),
        actions: const [_DashboardAvatar()],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddTransaction,
        icon: const Icon(AppIcons.add),
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
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Text(
            _initial(user?.displayName),
            style: TextStyle(color: colorScheme.primary),
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
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
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
      destinations: const [
        NavigationDestination(
          icon: Icon(AppIcons.dashboard),
          selectedIcon: Icon(AppIcons.dashboardSelected),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.transactions),
          selectedIcon: Icon(AppIcons.transactionsSelected),
          label: 'Transaksi',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.reports),
          selectedIcon: Icon(AppIcons.reportsSelected),
          label: 'Laporan',
        ),
        NavigationDestination(
          icon: Icon(AppIcons.settings),
          selectedIcon: Icon(AppIcons.settingsSelected),
          label: 'Pengaturan',
        ),
      ],
    );
  }
}

void _showAddTransactionSheet(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final semanticColors = context.semanticColors;
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: AppRadius.prominentTopBorder,
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
            leading: Icon(
              AppIcons.forTransactionType(TransactionType.income),
              color: semanticColors.onIncomeContainer,
              size: AppIconSize.regular,
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
            leading: Icon(
              AppIcons.forTransactionType(TransactionType.expense),
              color: semanticColors.onExpenseContainer,
              size: AppIconSize.regular,
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
            leading: Icon(
              AppIcons.transfer,
              color: semanticColors.onTransferContainer,
              size: AppIconSize.regular,
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
        borderRadius: AppRadius.prominentTopBorder,
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
                leading: SizedBox(
                  width: AppIconSize.regular,
                  child: cb.cashbookId == activeCashbook?.cashbookId
                      ? Icon(
                          AppIcons.selected,
                          color: colorScheme.primary,
                          semanticLabel: 'Buku kas aktif',
                        )
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
                        child: Text(
                          'Utama',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
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
              leading: Icon(
                AppIcons.manageCashbooks,
                color: colorScheme.primary,
              ),
              title: Text(
                'Kelola Buku Kas',
                style: TextStyle(color: colorScheme.primary),
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

    final cashbookName = activeCashbook?.cashbookName ?? 'Belum dipilih';
    return Semantics(
      button: true,
      label: 'Pilih buku kas. Saat ini $cashbookName',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Pilih buku kas',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.controlBorder,
            onTap: () {
              cashbooksAsync.whenData(
                (cashbooks) =>
                    _showBottomSheet(context, ref, activeCashbook, cashbooks),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppComponentHeight.interactive,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      activeCashbook?.cashbookName ?? 'Pilih Buku Kas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    AppIcons.dropdown,
                    color: colorScheme.onSurfaceVariant,
                    size: AppIconSize.small,
                  ),
                ],
              ),
            ),
          ),
        ),
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
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.prominent),
          bottomRight: Radius.circular(AppRadius.prominent),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.xs,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
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
              error: (_, __) => Text(
                '—',
                key: const ValueKey('error'),
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 28,
                ),
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
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Ringkasan ${DateFormatter.formatMonthYear(selectedMonth)}',
          ),
          const SizedBox(height: AppSpacing.xs),
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
                return _MonthlySummarySurface(
                  key: ValueKey('$income:$expense'),
                  income: income,
                  expense: expense,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.cardBorder,
      ),
      child: const Row(
        children: [
          Expanded(child: _SummaryMetricPlaceholder()),
          _SummaryDivider(),
          Expanded(child: _SummaryMetricPlaceholder()),
        ],
      ),
    );
  }
}

class _SummaryMetricPlaceholder extends StatelessWidget {
  const _SummaryMetricPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 10,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: AppRadius.smallBorder,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 88,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: AppRadius.smallBorder,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: VerticalDivider(
        width: AppSpacing.lg,
        thickness: AppBorder.subtleWidth,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _MonthlySummarySurface extends StatelessWidget {
  final int income;
  final int expense;

  const _MonthlySummarySurface({
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
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MoneyMetric(
              label: 'Pemasukan',
              value: CurrencyFormatter.format(income),
              type: MoneyMetricType.income,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: MoneyMetric(
              label: 'Pengeluaran',
              value: CurrencyFormatter.format(expense),
              type: MoneyMetricType.expense,
            ),
          ),
        ],
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
          padding: AppSpacing.screenPadding,
          child: AppSectionHeader(
            title: 'Dompet',
            actionLabel: 'Lihat Semua',
            onAction: () => context.push('/wallets'),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: walletsAsync.when(
            loading: () => const Padding(
              key: ValueKey('loading'),
              padding: AppSpacing.screenPadding,
              child: _WalletLoadingStrip(),
            ),
            error: (_, __) => Padding(
              key: const ValueKey('error'),
              padding: AppSpacing.screenPadding,
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
                  padding: const EdgeInsets.only(
                    left: AppSpacing.screenHorizontal,
                    right: AppSpacing.screenHorizontal,
                    top: AppSpacing.xs,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: AppRadius.cardBorder,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              AppIcons.walletFallback,
                              size: AppIconSize.object,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppSpacing.xs),
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
              return LayoutBuilder(
                key: ValueKey(wallets.length),
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth * 0.78)
                      .clamp(240.0, 280.0)
                      .toDouble();
                  return SizedBox(
                    height: AppComponentHeight.walletCard,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal - 4,
                      ),
                      itemCount: wallets.length,
                      itemBuilder: (_, index) =>
                          _WalletCard(wallet: wallets[index], width: cardWidth),
                    ),
                  );
                },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.78)
            .clamp(240.0, 280.0)
            .toDouble();
        return SizedBox(
          height: AppComponentHeight.walletCard,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal - 4,
            ),
            itemCount: 3,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: AppRadius.cardBorder,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AppIconSize.regular,
                      height: AppIconSize.regular,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: AppRadius.smallBorder,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 96,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: AppRadius.smallBorder,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 72,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: AppRadius.smallBorder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet Card (horizontal scroll item)
// ---------------------------------------------------------------------------

class _WalletCard extends StatelessWidget {
  final WalletEntity wallet;
  final double width;

  const _WalletCard({required this.wallet, required this.width});

  WalletPaletteEntry _paletteEntry(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkWalletPalette
        : AppColors.lightWalletPalette;
    final index = switch (wallet.type) {
      WalletType.cash => 3,
      WalletType.bankAcc => 0,
      WalletType.eWallet => 1,
    };
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final paletteEntry = _paletteEntry(context);
    final color = paletteEntry.background;
    final foregroundColor = paletteEntry.foreground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: SizedBox(
        width: width,
        child: Semantics(
          button: true,
          label:
              '${wallet.walletName}, ${CurrencyFormatter.format(wallet.currentBalance)}',
          child: Material(
            color: color,
            borderRadius: AppRadius.cardBorder,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/wallets/detail', extra: wallet),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      AppIcons.forWalletType(wallet.type),
                      color: foregroundColor,
                      size: AppIconSize.object,
                    ),
                    const Spacer(),
                    Text(
                      wallet.walletName,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      CurrencyFormatter.format(wallet.currentBalance),
                      style: TextStyle(color: foregroundColor, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: AppElevation.raised,
      borderRadius: AppRadius.cardBorder,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
                    color: colorScheme.primary,
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
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.controlBorder,
              ),
              child: Icon(
                isStep1 ? AppIcons.cashbook : AppIcons.walletFallback,
                color: colorScheme.onPrimaryContainer,
                size: AppIconSize.hero,
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
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(AppIcons.add),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? colorScheme.primary : colorScheme.primaryContainer,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? colorScheme.onPrimary
                : colorScheme.onPrimaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
