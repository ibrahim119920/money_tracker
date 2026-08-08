import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../icons/app_icons.dart';
import '../../providers/providers.dart';
import '../../widgets/sequential_flow_widgets.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionType type;
  final TransactionEntity? transaction;

  const TransactionFormScreen({
    super.key,
    required this.type,
    this.transaction,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryIcon;
  String? _selectedWalletId;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _categoryTouched = false;

  bool get _isEdit => widget.transaction != null;
  bool get _isIncome => widget.type == TransactionType.income;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(
      text: tx != null ? CurrencyFormatter.formatWithoutSymbol(tx.amount) : '',
    );
    _nameController = TextEditingController(text: tx?.name ?? '');
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _selectedDate = tx?.transactionDate ?? DateTime.now();
    _selectedCategoryId = tx?.categoryId;
    _selectedCategoryName = tx?.categoryName;
    _selectedCategoryIcon = tx?.categoryIcon;
    _selectedWalletId = tx?.walletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryPicker() async {
    final activeCashbook = ref.read(activeCashbookProvider);
    if (activeCashbook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku kas belum dipilih'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final category = await showModalBottomSheet<CategoryEntity>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.prominentTopBorder,
      ),
      builder: (_) => CategoryPickerSheet(
        cashbookId: activeCashbook.cashbookId,
        type: widget.type,
        selectedId: _selectedCategoryId,
      ),
    );
    if (category != null && mounted) {
      setState(() {
        _selectedCategoryId = category.categoryId;
        _selectedCategoryName = category.categoryName;
        _selectedCategoryIcon = category.icon;
        _categoryTouched = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 100),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _categoryTouched = true);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategoryId == null) return; // shown via inline error

    setState(() => _isLoading = true);

    try {
      final activeCashbook = ref.read(activeCashbookProvider);
      if (activeCashbook == null) {
        throw Exception('Buku kas tidak ditemukan');
      }

      final digits = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      final amount = int.parse(digits);
      final repository = ref.read(transactionRepositoryProvider);

      final trimmedName = _nameController.text.trim();
      final trimmedNotes = _notesController.text.trim();

      if (_isEdit) {
        await repository.updateTransaction(
          transactionId: widget.transaction!.transactionId,
          walletId: _selectedWalletId!,
          categoryId: _selectedCategoryId!,
          amount: amount,
          name: trimmedName.isEmpty ? null : trimmedName,
          notes: trimmedNotes.isEmpty ? null : trimmedNotes,
          transactionDate: _selectedDate,
        );
      } else {
        await repository.createTransaction(
          cashbookId: activeCashbook.cashbookId,
          walletId: _selectedWalletId!,
          categoryId: _selectedCategoryId!,
          type: widget.type,
          amount: amount,
          name: trimmedName.isEmpty ? null : trimmedName,
          notes: trimmedNotes.isEmpty ? null : trimmedNotes,
          transactionDate: _selectedDate,
        );
      }

      ref.invalidate(transactionsProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(futureTransactionProjectionProvider);
      ref.invalidate(cashbookBalanceProvider(activeCashbook.cashbookId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Transaksi berhasil diperbarui'
                  : 'Transaksi berhasil ditambahkan',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan transaksi. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _isIncome
        ? colorScheme.incomeContainer
        : colorScheme.expenseContainer;
    final typeForeground = _isIncome
        ? colorScheme.onIncomeColor
        : colorScheme.onExpenseColor;
    final title = _isEdit
        ? (_isIncome ? 'Edit Pemasukan' : 'Edit Pengeluaran')
        : (_isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: typeColor,
        foregroundColor: typeForeground,
        iconTheme: IconThemeData(color: typeForeground),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: typeForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _AmountField(
                controller: _amountController,
                typeColor: typeColor,
                typeForeground: typeForeground,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      _buildCategoryField(typeColor),
                      const SizedBox(height: AppSpacing.md),
                      _buildWalletField(),
                      const SizedBox(height: AppSpacing.md),
                      _buildDateField(),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          hintText: 'contoh: Makan siang, Gaji Maret',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        validator: Validators.validateNotes,
                        decoration: const InputDecoration(
                          labelText: 'Catatan',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: AppComponentHeight.interactive,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: typeForeground,
                            foregroundColor: typeColor,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: typeForeground,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField(Color typeColor) {
    final showError = _categoryTouched && _selectedCategoryId == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori *',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        InkWell(
          onTap: _showCategoryPicker,
          borderRadius: AppRadius.controlBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: showError
                  ? Border.all(
                      color: Theme.of(context).colorScheme.error,
                      width: AppBorder.focusWidth,
                    )
                  : null,
              borderRadius: AppRadius.controlBorder,
            ),
            child: Row(
              children: [
                if (_selectedCategoryIcon != null) ...[
                  Icon(
                    AppIcons.forCategory(
                      _selectedCategoryIcon,
                      categoryName: _selectedCategoryName,
                    ),
                    size: 20,
                    color: typeColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    _selectedCategoryName ?? 'Pilih Kategori',
                    style: TextStyle(
                      color: _selectedCategoryName != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxs, left: AppSpacing.md),
            child: Text(
              'Kategori harus dipilih',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWalletField() {
    final walletsAsync = ref.watch(walletsProvider);
    return walletsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => const Text('Gagal memuat dompet'),
      data: (wallets) {
        return DropdownButtonFormField<String>(
          initialValue: _selectedWalletId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Dompet *',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Pilih Dompet'),
          items: wallets.map((wallet) {
            return DropdownMenuItem<String>(
              value: wallet.walletId,
              child: Row(
                children: [
                  Icon(
                    _walletIcon(wallet.type),
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      wallet.walletName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    CurrencyFormatter.formatCompact(wallet.currentBalance),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedWalletId = val),
          validator: (val) => val == null ? 'Dompet harus dipilih' : null,
        );
      },
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal *',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        InkWell(
          key: const ValueKey('transaction-edit-date-control'),
          onTap: _pickDate,
          borderRadius: AppRadius.controlBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.controlBorder,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    DateFormatter.formatFullDate(_selectedDate),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _walletIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.account_balance_wallet_outlined;
      case WalletType.bankAcc:
        return Icons.account_balance_outlined;
      case WalletType.eWallet:
        return Icons.smartphone_outlined;
    }
  }
}

// ---------------------------------------------------------------------------
// Amount field widget with colored background
// ---------------------------------------------------------------------------
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color typeColor;
  final Color typeForeground;

  const _AmountField({
    required this.controller,
    required this.typeColor,
    required this.typeForeground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: typeColor,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      child: TextFormField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [_ThousandSeparatorFormatter()],
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: typeForeground,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          prefixText: 'Rp ',
          prefixStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: typeForeground,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: typeForeground.withValues(alpha: 0.45),
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: typeForeground, width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: typeForeground.withValues(alpha: 0.7),
            ),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: typeForeground, width: 2),
          ),
          errorStyle: TextStyle(color: typeForeground),
          hintText: '0',
          hintStyle: TextStyle(
            color: typeForeground.withValues(alpha: 0.65),
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        validator: Validators.validateAmount,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto thousand-separator formatter
// ---------------------------------------------------------------------------
class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final amount = int.tryParse(digits);
    if (amount == null) return oldValue;
    final formatted = CurrencyFormatter.formatWithoutSymbol(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
