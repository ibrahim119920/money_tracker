import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/money_metric.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  static const List<String> _monthNames = [
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

  static const List<String> _monthNamesFull = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
      body: const _MonthlyReportBody(),
    );
  }
}

class _MonthlyReportBody extends ConsumerWidget {
  const _MonthlyReportBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(reportMonthProvider);
    final activeCashbook = ref.watch(activeCashbookProvider);

    if (activeCashbook == null) {
      return const Center(child: Text('Buku kas tidak ditemukan'));
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
          AppSpacing.screenHorizontal,
          AppSpacing.xl,
        ),
        children: [
          _MonthPicker(selectedMonth: selectedMonth),
          const SizedBox(height: AppSpacing.lg),
          _SummarySection(
            selectedMonth: selectedMonth,
            cashbookId: activeCashbook.cashbookId,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PieChartSection(
            selectedMonth: selectedMonth,
            cashbookId: activeCashbook.cashbookId,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BarChartSection(
            cashbookId: activeCashbook.cashbookId,
            year: selectedMonth.year,
            selectedMonth: selectedMonth.month,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ============================================================================
// Month Picker
// ============================================================================
class _MonthPicker extends ConsumerWidget {
  final DateTime selectedMonth;

  const _MonthPicker({required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthName =
        MonthlyReportScreen._monthNamesFull[selectedMonth.month - 1];

    return Container(
      height: AppComponentHeight.interactive,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.controlBorder,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Bulan sebelumnya',
            onPressed: () {
              final prev = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              );
              ref.read(reportMonthProvider.notifier).state = prev;
            },
          ),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Pilih bulan $monthName ${selectedMonth.year}',
              child: TextButton(
                onPressed: () =>
                    _showMonthYearPicker(context, ref, selectedMonth),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppComponentHeight.interactive),
                  padding: EdgeInsets.zero,
                  foregroundColor: colorScheme.onSurface,
                ),
                child: Text(
                  '$monthName ${selectedMonth.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Bulan berikutnya',
            onPressed: () {
              final next = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
              );
              ref.read(reportMonthProvider.notifier).state = next;
            },
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _MonthYearPickerDialog(
        initialMonth: current,
        onSelected: (DateTime picked) {
          ref.read(reportMonthProvider.notifier).state = picked;
        },
      ),
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialMonth;
  final ValueChanged<DateTime> onSelected;

  const _MonthYearPickerDialog({
    required this.initialMonth,
    required this.onSelected,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Tahun sebelumnya',
            onPressed: () => setState(() => _selectedYear--),
          ),
          Text('$_selectedYear', style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Tahun berikutnya',
            onPressed: () => setState(() => _selectedYear++),
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
          ),
          itemCount: 12,
          itemBuilder: (_, i) {
            final isSelected = (i + 1) == _selectedMonth;
            return TextButton(
              onPressed: () {
                setState(() => _selectedMonth = i + 1);
                widget.onSelected(DateTime(_selectedYear, i + 1));
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppComponentHeight.interactive),
                padding: EdgeInsets.zero,
                backgroundColor: isSelected
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                foregroundColor: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.smallBorder,
                ),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(MonthlyReportScreen._monthNames[i]),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Summary Cards (P0)
// ============================================================================
class _SummarySection extends ConsumerWidget {
  final DateTime selectedMonth;
  final String cashbookId;

  const _SummarySection({
    required this.selectedMonth,
    required this.cashbookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final summaryAsync = ref.watch(reportMonthlySummaryProvider(selectedMonth));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: summaryAsync.when(
        loading: () => const _SummaryLoadingState(key: ValueKey('loading')),
        error: (_, _) => Padding(
          key: const ValueKey('error'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Gagal memuat ringkasan. Silakan coba lagi.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        data: (summary) {
          final income = summary['income'] ?? 0;
          final expense = summary['expense'] ?? 0;
          final net = income - expense;
          return Column(
            key: const ValueKey('data'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(title: 'Ringkasan Bulan Ini'),
              const SizedBox(height: AppSpacing.xs),
              _ReportSummarySurface(income: income, expense: expense, net: net),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryLoadingState extends StatelessWidget {
  const _SummaryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Ringkasan Bulan Ini'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.cardBorder,
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Expanded(child: _SummaryMetricSkeleton()),
                  _SummaryVerticalSkeleton(),
                  Expanded(child: _SummaryMetricSkeleton()),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              _SummaryNetSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportSummarySurface extends StatelessWidget {
  final int income;
  final int expense;
  final int net;

  const _ReportSummarySurface({
    required this.income,
    required this.expense,
    required this.net,
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MoneyMetric(
                  label: 'Pemasukan',
                  value: CurrencyFormatter.format(income),
                  type: MoneyMetricType.income,
                  compact: true,
                ),
              ),
              const _SummaryVerticalDivider(),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1),
          ),
          MoneyMetric(
            label: net >= 0 ? 'Surplus' : 'Defisit',
            value: '${net >= 0 ? '+' : ''}${CurrencyFormatter.format(net)}',
            color: net >= 0
                ? colorScheme.incomeColor
                : colorScheme.expenseColor,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryVerticalDivider extends StatelessWidget {
  const _SummaryVerticalDivider();

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

class _SummaryMetricSkeleton extends StatelessWidget {
  const _SummaryMetricSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 64, height: 10, color: color),
        const SizedBox(height: AppSpacing.xs),
        Container(width: 104, height: 16, color: color),
      ],
    );
  }
}

class _SummaryVerticalSkeleton extends StatelessWidget {
  const _SummaryVerticalSkeleton();

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

class _SummaryNetSkeleton extends StatelessWidget {
  const _SummaryNetSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(width: 64, height: 10, color: color),
        Container(width: 120, height: 16, color: color),
      ],
    );
  }
}

// ============================================================================
// Pie Chart — Category Breakdown (P1)
// ============================================================================
class _PieChartSection extends ConsumerStatefulWidget {
  final DateTime selectedMonth;
  final String cashbookId;

  const _PieChartSection({
    required this.selectedMonth,
    required this.cashbookId,
  });

  @override
  ConsumerState<_PieChartSection> createState() => _PieChartSectionState();
}

class _PieChartSectionState extends ConsumerState<_PieChartSection> {
  TransactionType _activeType = TransactionType.expense;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final breakdownAsync = ref.watch(
      reportCategoryBreakdownProvider((
        cashbookId: widget.cashbookId,
        month: widget.selectedMonth,
        transactionType: _activeType,
      )),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Distribusi Kategori'),
          const SizedBox(height: AppSpacing.xs),
          _ReportTypeSegmentedControl(
            activeType: _activeType,
            onChanged: (type) => setState(() => _activeType = type),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: breakdownAsync.when(
              loading: () =>
                  const _PieChartLoadingState(key: ValueKey('loading')),
              error: (_, _) => Padding(
                key: const ValueKey('error'),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Gagal memuat data. Silakan coba lagi.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SizedBox(
                    key: const ValueKey('empty'),
                    height: 120,
                    child: Center(
                      child: Text(
                        'Tidak ada data ${_activeType == TransactionType.expense ? 'pengeluaran' : 'pemasukan'}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }

                final displayItems = _prepareCategoryItems(items);
                final total = displayItems.fold<int>(
                  0,
                  (sum, item) => sum + (item['amount'] as int),
                );
                final sections = _buildPieSections(displayItems, total);

                return Column(
                  key: const ValueKey('data'),
                  children: [
                    SizedBox(
                      height: 168,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 42,
                              sectionsSpace: 2,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        response == null ||
                                        response.touchedSection == null) {
                                      _touchedIndex = null;
                                      return;
                                    }
                                    _touchedIndex = response
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatCompact(total),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CategoryLegend(items: displayItems, total: total),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _prepareCategoryItems(
    List<Map<String, dynamic>> items,
  ) {
    if (items.length <= 5) {
      return items;
    }

    final sortedItems = items.map(Map<String, dynamic>.from).toList()
      ..sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));

    final visibleItems = sortedItems.take(5).toList();
    final remainingAmount = sortedItems
        .skip(5)
        .fold<int>(0, (sum, item) => sum + (item['amount'] as int));

    if (remainingAmount > 0) {
      visibleItems.add({
        'categoryName': 'Lainnya',
        'amount': remainingAmount,
        'color': '#5B6E72',
      });
    }

    return visibleItems;
  }

  List<PieChartSectionData> _buildPieSections(
    List<Map<String, dynamic>> items,
    int total,
  ) {
    return List.generate(items.length, (i) {
      final item = items[i];
      final amount = item['amount'] as int;
      final percentage = total > 0 ? (amount / total * 100) : 0.0;
      final isTouched = i == _touchedIndex;
      final color = _colorFromHex(item['color'] as String? ?? '#9E9E9E');

      return PieChartSectionData(
        value: amount.toDouble(),
        color: color,
        radius: isTouched ? 54 : 46,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Color _colorFromHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.textSecondary;
    }
  }
}

class _ReportTypeSegmentedControl extends StatelessWidget {
  final TransactionType activeType;
  final ValueChanged<TransactionType> onChanged;

  const _ReportTypeSegmentedControl({
    required this.activeType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: AppComponentHeight.interactive + AppSpacing.xxs,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.controlBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _buildOption(
              context,
              type: TransactionType.expense,
              label: 'Pengeluaran',
              selectedColor: colorScheme.expenseContainer,
              selectedForeground: colorScheme.onExpenseColor,
            ),
          ),
          Expanded(
            child: _buildOption(
              context,
              type: TransactionType.income,
              label: 'Pemasukan',
              selectedColor: colorScheme.incomeContainer,
              selectedForeground: colorScheme.onIncomeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required TransactionType type,
    required String label,
    required Color selectedColor,
    required Color selectedForeground,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = activeType == type;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(type),
          borderRadius: AppRadius.smallBorder,
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : Colors.transparent,
              borderRadius: AppRadius.smallBorder,
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? selectedForeground
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int total;

  const _CategoryLegend({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: items.map((item) {
        final amount = item['amount'] as int;
        final percentage = total > 0 ? (amount / total * 100) : 0.0;
        final color = _colorFromHex(item['color'] as String? ?? '#9E9E9E');
        final categoryName = item['categoryName'] as String? ?? 'Lainnya';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  categoryName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 52,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 108,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyFormatter.format(amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _colorFromHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.textSecondary;
    }
  }
}

class _PieChartLoadingState extends StatelessWidget {
  const _PieChartLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 2 ? 0 : AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      borderRadius: AppRadius.smallBorder,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 52,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    borderRadius: AppRadius.smallBorder,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 108,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    borderRadius: AppRadius.smallBorder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Bar Chart — 12-Month Trend (P2)
// ============================================================================
class _BarChartSection extends ConsumerWidget {
  final String cashbookId;
  final int year;
  final int selectedMonth;

  const _BarChartSection({
    required this.cashbookId,
    required this.year,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final trendAsync = ref.watch(
      reportYearlyTrendProvider((cashbookId: cashbookId, year: year)),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Tren $year'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(color: colorScheme.incomeColor, label: 'Pemasukan'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(color: colorScheme.expenseColor, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: trendAsync.when(
              loading: () =>
                  const _BarChartLoadingState(key: ValueKey('loading')),
              error: (_, _) => Padding(
                key: const ValueKey('error'),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Gagal memuat data. Silakan coba lagi.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              data: (months) {
                if (months.every(
                  (m) => m['income'] == 0 && m['expense'] == 0,
                )) {
                  return SizedBox(
                    key: ValueKey('empty'),
                    height: 100,
                    child: Center(
                      child: Text(
                        'Belum ada transaksi tahun ini',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }

                final maxValue = months.fold<double>(1, (max, m) {
                  final income = (m['income'] ?? 0).toDouble();
                  final expense = (m['expense'] ?? 0).toDouble();
                  return [max, income, expense].reduce((a, b) => a > b ? a : b);
                });

                return SizedBox(
                  key: const ValueKey('data'),
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: maxValue * 1.2,
                      barGroups: _buildBarGroups(months, colorScheme),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final month = value.toInt();
                              if (month < 1 || month > 12) {
                                return const SizedBox.shrink();
                              }
                              final isSelected = month == selectedMonth;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  MonthlyReportScreen._monthNames[month - 1],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                CurrencyFormatter.formatCompact(value.toInt()),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxValue / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: colorScheme.outlineVariant,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = rodIndex == 0 ? 'Masuk' : 'Keluar';
                            return BarTooltipItem(
                              '$label\n${CurrencyFormatter.format(rod.toY.toInt())}',
                              const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<Map<String, int>> months,
    ColorScheme colorScheme,
  ) {
    return months.map((m) {
      final month = m['month']!;
      final income = (m['income'] ?? 0).toDouble();
      final expense = (m['expense'] ?? 0).toDouble();
      final isSelected = month == selectedMonth;

      return BarChartGroupData(
        x: month,
        groupVertically: false,
        barRods: [
          BarChartRodData(
            toY: income,
            color: colorScheme.incomeColor.withValues(
              alpha: isSelected ? 1.0 : 0.6,
            ),
            width: 6,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.small),
            ),
          ),
          BarChartRodData(
            toY: expense,
            color: colorScheme.expenseColor.withValues(
              alpha: isSelected ? 1.0 : 0.6,
            ),
            width: 6,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.small),
            ),
          ),
        ],
        barsSpace: 3,
      );
    }).toList();
  }
}

class _BarChartLoadingState extends StatelessWidget {
  const _BarChartLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            12,
            (index) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: (index % 4 + 2) * 18,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    borderRadius: AppRadius.smallBorder,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
