import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

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
    try {
      final allCategories = await ref.read(
        categoriesProvider(activeCashbook?.cashbookId).future,
      );
      final categories = allCategories
          .where((c) => c.type == widget.type)
          .toList();

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _CategoryPickerSheet(
          categories: categories,
          selectedId: _selectedCategoryId,
          onSelected: (category) {
            setState(() {
              _selectedCategoryId = category.categoryId;
              _selectedCategoryName = category.categoryName;
              _selectedCategoryIcon = category.icon;
              _categoryTouched = true;
            });
            Navigator.of(context).pop();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat kategori'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    final typeColor = _isIncome ? AppColors.income : AppColors.expense;
    final title = _isEdit
        ? (_isIncome ? 'Edit Pemasukan' : 'Edit Pengeluaran')
        : (_isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: typeColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _AmountField(controller: _amountController, typeColor: typeColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildCategoryField(typeColor),
                    const SizedBox(height: 16),
                    _buildWalletField(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
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
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
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
        const SizedBox(height: 4),
        InkWell(
          onTap: _showCategoryPicker,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: showError ? AppColors.error : AppColors.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_selectedCategoryIcon != null) ...[
                  Icon(Icons.category_outlined, size: 20, color: typeColor),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _selectedCategoryName ?? 'Pilih Kategori',
                    style: TextStyle(
                      color: _selectedCategoryName != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 12),
            child: Text(
              'Kategori harus dipilih',
              style: TextStyle(color: AppColors.error, fontSize: 12),
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
          value: _selectedWalletId,
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
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wallet.walletName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatCompact(wallet.currentBalance),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.formatFullDate(_selectedDate),
                  style: const TextStyle(fontSize: 16),
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

  const _AmountField({required this.controller, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: typeColor,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [_ThousandSeparatorFormatter()],
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          prefixText: 'Rp ',
          prefixStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70, width: 2),
          ),
          errorStyle: const TextStyle(color: Colors.white70),
          hintText: '0',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 28,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
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

// ---------------------------------------------------------------------------
// Category picker bottom sheet
// ---------------------------------------------------------------------------
class _CategoryPickerSheet extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  final void Function(CategoryEntity) onSelected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Kategori',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: categories.isEmpty
                  ? const Center(child: Text('Belum ada kategori'))
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category.categoryId == selectedId;
                        return GestureDetector(
                          onTap: () => onSelected(category),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.outline,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 28,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.categoryName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
