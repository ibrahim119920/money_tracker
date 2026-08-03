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
      locale: const Locale('id', 'ID'),
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
        const SnackBar(content: Text('Transfer berhasil ditambahkan')),
      );
    } catch (e) {
      if (!mounted) return;

      final raw = e.toString().toLowerCase();
      final message = raw.contains('saldo dompet asal tidak cukup')
          ? 'Saldo dompet asal tidak cukup'
          : raw.contains('tidak dapat transfer ke dompet yang sama')
          ? 'Tidak dapat transfer ke dompet yang sama'
          : 'Gagal menyimpan transfer. Silakan coba lagi.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    final colorScheme = Theme.of(context).colorScheme;
    final walletsAsync = ref.watch(walletsProvider);
    final transfersAsync = ref.watch(transfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Antar Dompet'),
        backgroundColor: colorScheme.transferContainer,
        foregroundColor: colorScheme.onTransferColor,
        iconTheme: IconThemeData(color: colorScheme.onTransferColor),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.onTransferColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              _buildTransferForm(walletsAsync),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Riwayat Transfer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildTransferHistory(transfersAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferForm(AsyncValue<List<WalletEntity>> walletsAsync) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: walletsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                    initialValue: _fromWalletId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dari Dompet *',
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
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _toWalletId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Ke Dompet *'),
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
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandSeparatorFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Transfer *',
                      prefixText: 'Rp ',
                    ),
                    validator: Validators.validateAmount,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: AppRadius.controlBorder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: AppRadius.controlBorder,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: AppIconSize.small,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            DateFormatter.formatFullDate(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      alignLabelWithHint: true,
                    ),
                    validator: Validators.validateNotes,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: AppComponentHeight.interactive,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveTransfer,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.transferColor,
                        foregroundColor: colorScheme.onTransferColor,
                      ),
                      icon: _isSaving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onTransferColor,
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
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.cardBorder,
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const Text('Gagal memuat riwayat transfer'),
              const SizedBox(height: AppSpacing.xs),
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
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBorder,
              color: colorScheme.surfaceContainerLow,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 44,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Belum ada transfer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }

        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.cardBorder,
          ),
          child: Column(
            children: transfers.asMap().entries.map((entry) {
              final index = entry.key;
              final transfer = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.transferContainer,
                        borderRadius: AppRadius.smallBorder,
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: colorScheme.transferColor,
                      ),
                    ),
                    title: Text(
                      '${transfer.fromWalletName ?? 'Dompet Asal'} → ${transfer.toWalletName ?? 'Dompet Tujuan'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          DateFormatter.formatLongDate(transfer.transferDate),
                        ),
                        if ((transfer.notes ?? '').trim().isNotEmpty)
                          Text(
                            transfer.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 112),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.format(transfer.amount),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colorScheme.transferColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                  if (index < transfers.length - 1)
                    const Divider(height: 1, indent: 52),
                ],
              );
            }).toList(),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(_walletIcon(wallet.type), size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(wallet.walletName, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text(
          CurrencyFormatter.formatCompact(wallet.currentBalance),
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
