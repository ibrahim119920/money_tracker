import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/transaction_tile.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String? _selectedType; // null = Semua, 'income', 'expense'

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
    );
  }

  void _onTypeChanged(String? type) {
    setState(() => _selectedType = type);
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
    );
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
    final selectedMonth = ref.watch(selectedMonthProvider);
    final transactionsAsync = ref.watch(transactionListItemsProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────────────
          _FilterBar(
            selectedType: _selectedType,
            selectedMonth: selectedMonth,
            onTypeChanged: _onTypeChanged,
            onMonthTap: _pickMonth,
          ),

          // ── Summary bar ─────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: summaryAsync.when(
              loading: () =>
                  const _SummaryBarPlaceholder(key: ValueKey('loading')),
              error: (_, __) => const SizedBox.shrink(key: ValueKey('error')),
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
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
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      if (item.isHeader) {
                        return _DateHeader(date: item.date!);
                      }
                      return TransactionTile(
                        transaction: item.transaction!,
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

  const _FilterBar({
    required this.selectedType,
    required this.selectedMonth,
    required this.onTypeChanged,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Type filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  _TypeChip(
                    label: 'Semua',
                    isSelected: selectedType == null,
                    onTap: () => onTypeChanged(null),
                  ),
                  _TypeChip(
                    label: 'Pemasukan',
                    isSelected: selectedType == 'income',
                    onTap: () => onTypeChanged('income'),
                    selectedColor: AppColors.income,
                  ),
                  _TypeChip(
                    label: 'Pengeluaran',
                    isSelected: selectedType == 'expense',
                    onTap: () => onTypeChanged('expense'),
                    selectedColor: AppColors.expense,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Month picker button
          OutlinedButton.icon(
            onPressed: onMonthTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            label: Text(
              DateFormatter.formatMonthYear(selectedMonth),
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.12)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : colorScheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? selectedColor : colorScheme.onSurfaceVariant,
          ),
        ),
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
    final netColor = net >= 0 ? AppColors.primary : AppColors.expense;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: 'Pemasukan',
              amount: CurrencyFormatter.formatCompact(income),
              color: AppColors.income,
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.outlineVariant),
          Expanded(
            child: _SummaryStat(
              label: 'Pengeluaran',
              amount: CurrencyFormatter.formatCompact(expense),
              color: AppColors.expense,
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.outlineVariant),
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
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: const [
          Expanded(child: _SummaryStatPlaceholder()),
          SizedBox(width: 12),
          Expanded(child: _SummaryStatPlaceholder()),
          SizedBox(width: 12),
          Expanded(child: _SummaryStatPlaceholder()),
        ],
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
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6, top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        DateFormatter.formatFullDate(date),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'di bulan ini',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (_, index) => Padding(
        padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: const ListTile(
            leading: _TransactionLoadingLeading(),
            title: _TransactionLoadingLine(width: 132),
            subtitle: _TransactionLoadingLine(width: 172, height: 10),
            trailing: _TransactionLoadingLine(width: 72, height: 14),
          ),
        ),
      ),
    );
  }
}

class _TransactionLoadingLeading extends StatelessWidget {
  const _TransactionLoadingLeading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.outlineVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
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

            return GestureDetector(
              onTap: isFuture
                  ? null
                  : () => Navigator.of(context).pop(DateTime(_year, month)),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  _monthLabels[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isFuture
                        ? AppColors.textTertiary
                        : isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
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
