import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/transaction_tile.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const TransactionListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyMonthFilter(ref.read(selectedMonthProvider));
    });
  }

  void _applyMonthFilter(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final currentType = ref.read(transactionFilterProvider).type;
    ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
      startDate: monthStart,
      endDate: monthEnd,
      type: currentType,
      categoryId: ref.read(transactionFilterProvider).categoryId,
      walletId: ref.read(transactionFilterProvider).walletId,
    );
    _refreshTransactionQuery();
  }

  void _onTypeChanged(String? type) {
    final currentFilter = ref.read(transactionFilterProvider);
    final transactionType = type == 'income'
        ? TransactionType.income
        : type == 'expense'
        ? TransactionType.expense
        : null;
    ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
      startDate: currentFilter.startDate,
      endDate: currentFilter.endDate,
      type: transactionType,
      categoryId: currentFilter.categoryId,
      walletId: currentFilter.walletId,
    );
    _refreshTransactionQuery();
  }

  void _onMonthStep(int offset) {
    final current = ref.read(selectedMonthProvider);
    final next = DateTime(current.year, current.month + offset);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    if (next.isAfter(currentMonth)) return;

    ref.read(selectedMonthProvider.notifier).state = next;
    _applyMonthFilter(next);
  }

  void _refreshTransactionQuery() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(transactionListItemsProvider);
  }

  Future<void> _pickMonth() async {
    final current = ref.read(selectedMonthProvider);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initialMonth: current),
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).state = picked;
      _applyMonthFilter(picked);
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(transactionsProvider);
    ref.invalidate(transactionListItemsProvider);
    ref.invalidate(monthlySummaryProvider);
    // Wait for the providers to reload
    await Future.wait([
      ref
          .read(transactionsProvider.future)
          .catchError((_) => <TransactionEntity>[]),
      ref
          .read(monthlySummaryProvider.future)
          .catchError((_) => <String, int>{}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedType = ref.watch(transactionFilterProvider).type?.value;
    final transactionsAsync = ref.watch(transactionListItemsProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    final body = SafeArea(
      top: false,
      child: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────────────
          _FilterBar(
            selectedType: selectedType,
            selectedMonth: selectedMonth,
            onTypeChanged: _onTypeChanged,
            onMonthTap: _pickMonth,
            onPreviousMonth: () => _onMonthStep(-1),
            onNextMonth: () => _onMonthStep(1),
            canGoNext: !selectedMonth.isAtSameMomentAs(
              DateTime(DateTime.now().year, DateTime.now().month),
            ),
          ),

          // ── Summary bar ─────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: summaryAsync.when(
              loading: () =>
                  const _SummaryBarPlaceholder(key: ValueKey('loading')),
              error: (_, _) => const SizedBox.shrink(key: ValueKey('error')),
              data: (summary) {
                final income = summary['income'] ?? 0;
                final expense = summary['expense'] ?? 0;
                final net = income - expense;
                return _SummaryBar(
                  key: ValueKey('$income:$expense:$net'),
                  income: income,
                  expense: expense,
                  net: net,
                );
              },
            ),
          ),

          // ── Transaction list ─────────────────────────────────────────────
          Expanded(
            child: transactionsAsync.when(
              loading: () => const _TransactionListLoading(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    const Text('Gagal memuat transaksi'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(transactionsProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      if (item.isHeader) {
                        return _DateHeader(date: item.date!);
                      }
                      return TransactionTile(
                        transaction: item.transaction!,
                        dense: true,
                        showDivider: index < transactions.length - 1,
                        onTap: () => context.push(
                          '/transactions/detail',
                          extra: item.transaction,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------
class _FilterBar extends StatelessWidget {
  final String? selectedType;
  final DateTime selectedMonth;
  final void Function(String?) onTypeChanged;
  final VoidCallback onMonthTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool canGoNext;

  const _FilterBar({
    required this.selectedType,
    required this.selectedMonth,
    required this.onTypeChanged,
    required this.onMonthTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TypeFilterSegmentedControl(
            selectedType: selectedType,
            onTypeChanged: onTypeChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          _MonthNavigation(
            selectedMonth: selectedMonth,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: canGoNext ? onNextMonth : null,
            onMonthTap: onMonthTap,
          ),
        ],
      ),
    );
  }
}

class _TypeFilterSegmentedControl extends StatelessWidget {
  final String? selectedType;
  final void Function(String?) onTypeChanged;

  const _TypeFilterSegmentedControl({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final options = [
      _TypeFilterOption(
        label: 'Semua',
        value: null,
        flex: 4,
        selectedColor: colorScheme.primaryContainer,
        selectedForeground: colorScheme.onPrimaryContainer,
      ),
      _TypeFilterOption(
        label: 'Pemasukan',
        value: 'income',
        flex: 9,
        selectedColor: colorScheme.incomeContainer,
        selectedForeground: colorScheme.onIncomeColor,
      ),
      _TypeFilterOption(
        label: 'Pengeluaran',
        value: 'expense',
        flex: 11,
        selectedColor: colorScheme.expenseContainer,
        selectedForeground: colorScheme.onExpenseColor,
      ),
    ];

    return Container(
      height: AppComponentHeight.interactive,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.controlBorder,
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              flex: option.flex,
              child: _TypeFilterSegment(
                option: option,
                isSelected: selectedType == option.value,
                onTap: () => onTypeChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeFilterOption {
  final String label;
  final String? value;
  final int flex;
  final Color selectedColor;
  final Color selectedForeground;

  const _TypeFilterOption({
    required this.label,
    required this.value,
    required this.flex,
    required this.selectedColor,
    required this.selectedForeground,
  });
}

class _TypeFilterSegment extends StatelessWidget {
  final _TypeFilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeFilterSegment({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filter ${option.label}',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: isSelected ? option.selectedColor : Colors.transparent,
          borderRadius: AppRadius.smallBorder,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.smallBorder,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? option.selectedForeground
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthNavigation extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback onMonthTap;

  const _MonthNavigation({
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthLabel = DateFormatter.formatMonthYear(selectedMonth);

    return Container(
      height: AppComponentHeight.interactive,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.controlBorder,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPreviousMonth,
            tooltip: 'Bulan sebelumnya',
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Pilih bulan $monthLabel',
              child: TextButton(
                onPressed: onMonthTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppComponentHeight.interactive),
                  padding: EdgeInsets.zero,
                  foregroundColor: colorScheme.onSurface,
                ),
                child: Text(
                  monthLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNextMonth,
            tooltip: 'Bulan berikutnya',
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary bar
// ---------------------------------------------------------------------------
class _SummaryBar extends StatelessWidget {
  final int income;
  final int expense;
  final int net;

  const _SummaryBar({
    super.key,
    required this.income,
    required this.expense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = colorScheme.brightness;
    final netColor = net >= 0
        ? AppColors.incomeForeground(brightness)
        : AppColors.expenseForeground(brightness);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: 'Pemasukan',
              amount: CurrencyFormatter.formatCompact(income),
              color: AppColors.incomeForeground(brightness),
            ),
          ),
          VerticalDivider(
            width: AppSpacing.md,
            thickness: AppBorder.subtleWidth,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: _SummaryStat(
              label: 'Pengeluaran',
              amount: CurrencyFormatter.formatCompact(expense),
              color: AppColors.expenseForeground(brightness),
            ),
          ),
          VerticalDivider(
            width: AppSpacing.md,
            thickness: AppBorder.subtleWidth,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: _SummaryStat(
              label: 'Selisih',
              amount: CurrencyFormatter.formatCompact(net.abs()),
              color: netColor,
              prefix: net < 0 ? '-' : '',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBarPlaceholder extends StatelessWidget {
  const _SummaryBarPlaceholder({super.key});

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
        children: const [
          Expanded(child: _SummaryStatPlaceholder()),
          _SummaryDividerPlaceholder(),
          Expanded(child: _SummaryStatPlaceholder()),
          _SummaryDividerPlaceholder(),
          Expanded(child: _SummaryStatPlaceholder()),
        ],
      ),
    );
  }
}

class _SummaryDividerPlaceholder extends StatelessWidget {
  const _SummaryDividerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: AppSpacing.md,
      child: VerticalDivider(
        thickness: AppBorder.subtleWidth,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _SummaryStatPlaceholder extends StatelessWidget {
  const _SummaryStatPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(width: 48, height: 10, color: colorScheme.outlineVariant),
        const SizedBox(height: 6),
        Container(width: 72, height: 14, color: colorScheme.outlineVariant),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final String prefix;

  const _SummaryStat({
    required this.label,
    required this.amount,
    required this.color,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          '$prefix$amount',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date header
// ---------------------------------------------------------------------------
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            '${DateFormatter.getDayName(date)}, ${date.day} ${DateFormatter.getMonthName(date)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(height: 1, color: colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text('di bulan ini', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TransactionListLoading extends StatelessWidget {
  const _TransactionListLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      itemCount: 5,
      separatorBuilder: (_, _) =>
          Divider(height: 1, indent: 52, color: colorScheme.outlineVariant),
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            const _TransactionLoadingLeading(),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TransactionLoadingLine(width: 132),
                  SizedBox(height: AppSpacing.xs),
                  _TransactionLoadingLine(width: 172, height: 10),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TransactionLoadingLine(width: index.isEven ? 84 : 72, height: 14),
          ],
        ),
      ),
    );
  }
}

class _TransactionLoadingLeading extends StatelessWidget {
  const _TransactionLoadingLeading();

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

class _TransactionLoadingLine extends StatelessWidget {
  final double width;
  final double height;

  const _TransactionLoadingLine({required this.width, this.height = 12});

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

// ---------------------------------------------------------------------------
// Month picker dialog
// ---------------------------------------------------------------------------
class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialMonth;

  const _MonthPickerDialog({required this.initialMonth});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Text(
            '$_year',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _year < now.year ? () => setState(() => _year++) : null,
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.2,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isFuture = DateTime(
              _year,
              month,
            ).isAfter(DateTime(now.year, now.month));
            final isSelected =
                month == widget.initialMonth.month &&
                _year == widget.initialMonth.year;

            return Padding(
              padding: const EdgeInsets.all(3),
              child: TextButton(
                onPressed: isFuture
                    ? null
                    : () => Navigator.of(context).pop(DateTime(_year, month)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: EdgeInsets.zero,
                  backgroundColor: isSelected
                      ? colorScheme.primary
                      : Colors.transparent,
                  foregroundColor: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  disabledForegroundColor: colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.smallBorder,
                  ),
                  textStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                child: Text(_monthLabels[index]),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
