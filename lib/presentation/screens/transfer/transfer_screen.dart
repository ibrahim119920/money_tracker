import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _fromWalletId;
  String? _toWalletId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _saveTransfer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fromWalletId == null || _toWalletId == null) return;

    setState(() => _isSaving = true);

    try {
      final activeCashbook = ref.read(activeCashbookProvider);
      if (activeCashbook == null) {
        throw Exception('Buku kas tidak ditemukan');
      }

      final amountDigits = _amountController.text.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final amount = int.parse(amountDigits);

      final repository = ref.read(transactionRepositoryProvider);
      final notes = _notesController.text.trim();

      await repository.createTransfer(
        cashbookId: activeCashbook.cashbookId,
        fromWalletId: _fromWalletId!,
        toWalletId: _toWalletId!,
        amount: amount,
        notes: notes.isEmpty ? null : notes,
        transferDate: _selectedDate,
      );

      ref.invalidate(transfersProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go(AppRoutes.dashboard);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transfer berhasil ditambahkan'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final raw = e.toString().toLowerCase();
      final message = raw.contains('saldo dompet asal tidak cukup')
          ? 'Saldo dompet asal tidak cukup'
          : raw.contains('tidak dapat transfer ke dompet yang sama')
          ? 'Tidak dapat transfer ke dompet yang sama'
          : 'Gagal menyimpan transfer. Silakan coba lagi.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(transfersProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(totalBalanceProvider);

    await Future.wait([
      ref.read(transfersProvider.future).catchError((_) => <TransferEntity>[]),
      ref.read(walletsProvider.future).catchError((_) => <WalletEntity>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final transfersAsync = ref.watch(transfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Antar Dompet'),
        backgroundColor: AppColors.transfer,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTransferForm(walletsAsync),
            const SizedBox(height: 20),
            const Text(
              'Riwayat Transfer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildTransferHistory(transfersAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferForm(AsyncValue<List<WalletEntity>> walletsAsync) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: walletsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Gagal memuat dompet'),
          ),
          data: (wallets) {
            if (wallets.length < 2) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Minimal harus ada 2 dompet aktif untuk melakukan transfer.',
                ),
              );
            }

            final toWalletOptions = wallets
                .where((wallet) => wallet.walletId != _fromWalletId)
                .toList();

            if (_toWalletId != null &&
                toWalletOptions.every(
                  (wallet) => wallet.walletId != _toWalletId,
                )) {
              _toWalletId = null;
            }

            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _fromWalletId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dari Dompet *',
                      border: OutlineInputBorder(),
                    ),
                    items: wallets.map((wallet) {
                      return DropdownMenuItem<String>(
                        value: wallet.walletId,
                        child: _WalletDropdownItem(wallet: wallet),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fromWalletId = value;
                        if (_toWalletId == value) {
                          _toWalletId = null;
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Dompet asal harus dipilih' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _toWalletId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ke Dompet *',
                      border: OutlineInputBorder(),
                    ),
                    items: toWalletOptions.map((wallet) {
                      return DropdownMenuItem<String>(
                        value: wallet.walletId,
                        child: _WalletDropdownItem(wallet: wallet),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _toWalletId = value),
                    validator: (value) {
                      if (value == null) return 'Dompet tujuan harus dipilih';
                      if (value == _fromWalletId) {
                        return 'Tidak dapat transfer ke dompet yang sama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandSeparatorFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Transfer *',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateAmount,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outline),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: Validators.validateNotes,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.transfer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.swap_horiz),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Transfer',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransferHistory(
    AsyncValue<List<TransferEntity>> transfersAsync,
  ) {
    return transfersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Gagal memuat riwayat transfer'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(transfersProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (transfers) {
        if (transfers.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
              color: Colors.white,
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 44,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 10),
                Text(
                  'Belum ada transfer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: transfers.map((transfer) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.transfer.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: AppColors.transfer,
                  ),
                ),
                title: Text(
                  '${transfer.fromWalletName ?? 'Dompet Asal'} -> ${transfer.toWalletName ?? 'Dompet Tujuan'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(DateFormatter.formatLongDate(transfer.transferDate)),
                    if ((transfer.notes ?? '').trim().isNotEmpty)
                      Text(
                        transfer.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: Text(
                  CurrencyFormatter.format(transfer.amount),
                  style: const TextStyle(
                    color: AppColors.transfer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _WalletDropdownItem extends StatelessWidget {
  final WalletEntity wallet;

  const _WalletDropdownItem({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_walletIcon(wallet.type), size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(wallet.walletName, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text(
          CurrencyFormatter.formatCompact(wallet.currentBalance),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
