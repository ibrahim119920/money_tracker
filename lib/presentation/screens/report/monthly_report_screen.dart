import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

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
    final selectedMonth = ref.watch(reportMonthProvider);
    final activeCashbook = ref.watch(activeCashbookProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: activeCashbook == null
          ? const Center(child: Text('Buku kas tidak ditemukan'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MonthPicker(selectedMonth: selectedMonth),
                const SizedBox(height: 16),
                _SummarySection(
                  selectedMonth: selectedMonth,
                  cashbookId: activeCashbook.cashbookId,
                ),
                const SizedBox(height: 24),
                _PieChartSection(
                  selectedMonth: selectedMonth,
                  cashbookId: activeCashbook.cashbookId,
                ),
                const SizedBox(height: 24),
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
    final monthName =
        MonthlyReportScreen._monthNamesFull[selectedMonth.month - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final prev = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              );
              ref.read(reportMonthProvider.notifier).state = prev;
            },
          ),
          GestureDetector(
            onTap: () => _showMonthYearPicker(context, ref, selectedMonth),
            child: Text(
              '$monthName ${selectedMonth.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
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
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _selectedYear--),
          ),
          Text(
            '$_selectedYear',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
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
            childAspectRatio: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (_, i) {
            final isSelected = (i + 1) == _selectedMonth;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedMonth = i + 1);
                widget.onSelected(DateTime(_selectedYear, i + 1));
                Navigator.of(context).pop();
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  MonthlyReportScreen._monthNames[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
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
    final summaryAsync = ref.watch(reportMonthlySummaryProvider(selectedMonth));

    return summaryAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Gagal memuat ringkasan: $e'),
      data: (summary) {
        final income = summary['income'] ?? 0;
        final expense = summary['expense'] ?? 0;
        final net = income - expense;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Bulan Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Pemasukan',
                    amount: income,
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    label: 'Pengeluaran',
                    amount: expense,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _NetCard(net: net),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NetCard extends StatelessWidget {
  final int net;

  const _NetCard({required this.net});

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;
    final color = isPositive ? AppColors.income : AppColors.expense;
    final label = isPositive ? 'Surplus' : 'Defisit';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${CurrencyFormatter.format(net)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
    final breakdownAsync = ref.watch(
      reportCategoryBreakdownProvider((
        cashbookId: widget.cashbookId,
        month: widget.selectedMonth,
        transactionType: _activeType,
      )),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Distribusi Kategori',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              // Toggle income/expense
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypeToggle(
                      label: 'Keluar',
                      isSelected: _activeType == TransactionType.expense,
                      color: AppColors.expense,
                      onTap: () =>
                          setState(() => _activeType = TransactionType.expense),
                    ),
                    _TypeToggle(
                      label: 'Masuk',
                      isSelected: _activeType == TransactionType.income,
                      color: AppColors.income,
                      onTap: () =>
                          setState(() => _activeType = TransactionType.income),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          breakdownAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Gagal memuat data: $e'),
            data: (items) {
              if (items.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Tidak ada data ${_activeType == TransactionType.expense ? 'pengeluaran' : 'pemasukan'}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              final total = items.fold<int>(
                0,
                (sum, item) => sum + (item['amount'] as int),
              );
              final sections = _buildPieSections(items, total);

              return Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 52,
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCompact(total),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CategoryLegend(items: items, total: total),
                ],
              );
            },
          ),
        ],
      ),
    );
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
        radius: isTouched ? 68 : 56,
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

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
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
    final displayItems = items.take(6).toList();

    return Column(
      children: displayItems.map((item) {
        final amount = item['amount'] as int;
        final percentage = total > 0 ? (amount / total * 100) : 0.0;
        final color = _colorFromHex(item['color'] as String? ?? '#9E9E9E');
        final categoryName = item['categoryName'] as String? ?? 'Lainnya';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
    final trendAsync = ref.watch(
      reportYearlyTrendProvider((cashbookId: cashbookId, year: year)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren $year',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.income, label: 'Pemasukan'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.expense, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 16),
          trendAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Gagal memuat data: $e'),
            data: (months) {
              if (months.every((m) => m['income'] == 0 && m['expense'] == 0)) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Belum ada transaksi tahun ini',
                      style: TextStyle(color: AppColors.textSecondary),
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
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue * 1.2,
                    barGroups: _buildBarGroups(months),
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
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
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
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
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
                        color: AppColors.outlineVariant,
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
                            const TextStyle(fontSize: 11, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, int>> months) {
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
            color: AppColors.income.withValues(alpha: isSelected ? 1.0 : 0.6),
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expense,
            color: AppColors.expense.withValues(alpha: isSelected ? 1.0 : 0.6),
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 3,
      );
    }).toList();
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
