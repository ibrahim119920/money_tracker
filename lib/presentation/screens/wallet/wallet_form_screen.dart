import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

/// Form screen untuk menambah/edit dompet
class WalletFormScreen extends ConsumerStatefulWidget {
  final WalletEntity? wallet;

  const WalletFormScreen({Key? key, this.wallet}) : super(key: key);

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen> {
  late final TextEditingController _walletNameCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _initialBalanceCtrl;

  late String _selectedType;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.wallet?.type.value ?? 'cash';

    _walletNameCtrl = TextEditingController(
      text: widget.wallet?.walletName ?? '',
    );
    _bankNameCtrl = TextEditingController(text: widget.wallet?.bankName ?? '');
    _accountNumberCtrl = TextEditingController(
      text: widget.wallet?.accountNumber ?? '',
    );
    _initialBalanceCtrl = TextEditingController(
      text: widget.wallet == null
          ? ''
          : CurrencyFormatter.formatWithoutSymbol(
              widget.wallet!.initialBalance,
            ),
    );
  }

  @override
  void dispose() {
    _walletNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _initialBalanceCtrl.dispose();
    super.dispose();
  }

  String _getWalletNameHint(String type) {
    switch (type) {
      case 'cash':
        return 'contoh: Dompet, Kas Kecil';
      case 'bank_acc':
        return 'contoh: BCA Tabungan, Mandiri';
      case 'ewallet':
        return 'contoh: GoPay, OVO, Dana';
      default:
        return '';
    }
  }

  String _getBankNameLabel(String type) {
    return type == 'bank_acc' ? 'Nama Bank' : 'Nama E-Wallet';
  }

  String _getBankNameHint(String type) {
    return type == 'bank_acc'
        ? 'contoh: BCA, Mandiri, BRI'
        : 'contoh: GoPay, OVO, Dana';
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final walletRepository = ref.read(walletRepositoryProvider);
      final walletName = _walletNameCtrl.text.trim();
      final bankName = _bankNameCtrl.text.trim();
      final accountNumber = _accountNumberCtrl.text.trim();
      final walletType =
          WalletType.fromString(_selectedType) ?? WalletType.cash;

      if (widget.wallet == null) {
        // Mode TAMBAH
        final activeCashbook = ref.read(activeCashbookProvider);
        if (activeCashbook == null) {
          throw Exception('Tentukan buku kas terlebih dahulu');
        }

        final initialBalance =
            CurrencyFormatter.parse(_initialBalanceCtrl.text) ?? 0;

        await walletRepository.createWallet(
          cashbookId: activeCashbook.cashbookId,
          type: walletType,
          walletName: walletName,
          bankName: bankName.isEmpty ? null : bankName,
          accountNumber: accountNumber.isEmpty ? null : accountNumber,
          initialBalance: initialBalance,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dompet berhasil ditambahkan'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Mode EDIT
        await walletRepository.updateWallet(
          walletId: widget.wallet!.walletId,
          walletName: walletName,
          bankName: bankName.isEmpty ? null : bankName,
          accountNumber: accountNumber.isEmpty ? null : accountNumber,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Dompet berhasil diperbarui'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      // Invalidate providers
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.wallet != null;
    final title = isEditMode ? 'Edit Dompet' : 'Tambah Dompet';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    label: const Text('Tipe Dompet'),
                    enabled: !isEditMode && !_isLoading,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Row(
                        children: [
                          Icon(Icons.payments, size: 20),
                          const SizedBox(width: 8),
                          const Text('Tunai'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'bank_acc',
                      child: Row(
                        children: [
                          Icon(Icons.account_balance, size: 20),
                          const SizedBox(width: 8),
                          const Text('Rekening Bank'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ewallet',
                      child: Row(
                        children: [
                          Icon(Icons.phone_android, size: 20),
                          const SizedBox(width: 8),
                          const Text('Dompet Digital'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: isEditMode
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Wallet Name Field
                TextFormField(
                  controller: _walletNameCtrl,
                  decoration: InputDecoration(
                    label: const Text('Nama Dompet'),
                    hintText: _getWalletNameHint(_selectedType),
                    enabled: !_isLoading,
                  ),
                  validator: (value) =>
                      Validators.validateRequired(value, 'Nama dompet'),
                ),
                const SizedBox(height: 16),

                // Bank/E-Wallet Name Field (conditional)
                if (_selectedType != 'cash') ...[
                  TextFormField(
                    controller: _bankNameCtrl,
                    decoration: InputDecoration(
                      label: Text(_getBankNameLabel(_selectedType)),
                      hintText: _getBankNameHint(_selectedType),
                      enabled: !_isLoading,
                    ),
                    validator: (value) => Validators.validateRequired(
                      value,
                      _getBankNameLabel(_selectedType),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Account Number Field (conditional, only for bank)
                if (_selectedType == 'bank_acc') ...[
                  TextFormField(
                    controller: _accountNumberCtrl,
                    decoration: InputDecoration(
                      label: const Text('Nomor Rekening'),
                      hintText: 'Opsional',
                      enabled: !_isLoading,
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateAccountNumber,
                  ),
                  const SizedBox(height: 16),
                ],

                // Initial Balance Field (only for create mode)
                if (!isEditMode) ...[
                  TextFormField(
                    controller: _initialBalanceCtrl,
                    decoration: InputDecoration(
                      label: const Text('Saldo Awal'),
                      prefixText: 'Rp ',
                      enabled: !_isLoading,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Auto-format dengan titik ribuan
                      if (value.isEmpty) return;

                      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                      final formatted = CurrencyFormatter.formatWithoutSymbol(
                        int.tryParse(cleanValue) ?? 0,
                      );

                      if (_initialBalanceCtrl.text != formatted) {
                        _initialBalanceCtrl.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.fromPosition(
                            TextPosition(offset: formatted.length),
                          ),
                        );
                      }
                    },
                    validator: Validators.validateAmount,
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveWallet,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
