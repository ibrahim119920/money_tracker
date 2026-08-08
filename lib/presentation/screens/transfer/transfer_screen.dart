import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../state/sequential_add_state.dart';
import '../../widgets/sequential_flow_widgets.dart';

/// Five-step transfer add flow. Transfer history is kept on its own route.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  static const _totalSteps = 5;

  late final PageController _pageController;
  late final TextEditingController _notesController;
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _notesController = TextEditingController(
      text: ref.read(transferDraftProvider).notes,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_isSubmitting) return;
    if (_currentStep == 0) {
      context.pop();
      return;
    }
    _goToStep(_currentStep - 1);
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps || step == _currentStep) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: AppMotion.standard,
      curve: Curves.easeOutCubic,
    );
  }

  bool _sourceIsEligible(WalletEntity wallet, TransferDraft draft) {
    return isTransferSourceSufficient(wallet, draft.amount);
  }

  bool _canContinue(
    TransferDraft draft,
    AsyncValue<List<WalletEntity>> walletsAsync,
  ) {
    switch (_currentStep) {
      case 0:
        return Validators.validateAmountValue(draft.amount) == null;
      case 1:
        return walletsAsync.whenOrNull(
              data: (wallets) {
                final source = _findWallet(wallets, draft.sourceWalletId);
                return source != null && _sourceIsEligible(source, draft);
              },
            ) ??
            false;
      case 2:
        return walletsAsync.whenOrNull(
              data: (wallets) {
                final destination = _findWallet(
                  wallets,
                  draft.destinationWalletId,
                );
                return wallets.length >= 2 &&
                    destination != null &&
                    destination.walletId != draft.sourceWalletId;
              },
            ) ??
            false;
      case 3:
        return Validators.validatePastDate(draft.transferDate) == null;
      case 4:
        return Validators.validateNotes(draft.notes) == null;
      default:
        return false;
    }
  }

  void _goNext(
    TransferDraft draft,
    AsyncValue<List<WalletEntity>> walletsAsync,
  ) {
    if (_isSubmitting) return;
    if (!_canContinue(draft, walletsAsync)) {
      _showValidationMessage();
      return;
    }
    if (_currentStep == _totalSteps - 1) {
      _submit(draft);
      return;
    }
    _goToStep(_currentStep + 1);
  }

  void _showValidationMessage() {
    final message = switch (_currentStep) {
      0 => 'Masukkan jumlah lebih dari 0',
      1 => 'Pilih dompet asal dengan saldo yang mencukupi',
      2 => 'Pilih dompet tujuan yang berbeda',
      3 => 'Pilih tanggal yang valid',
      _ =>
        Validators.validateNotes(ref.read(transferDraftProvider).notes) ??
            'Lengkapi catatan',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final draft = ref.read(transferDraftProvider);
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.transferDate,
      firstDate: DateTime(2000),
      lastDate: today,
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && mounted) {
      ref.read(transferDraftProvider.notifier).setDate(picked);
    }
  }

  Future<void> _openWalletForm() async {
    await context.push('/wallets/form');
    if (mounted) ref.invalidate(walletsProvider);
  }

  Future<void> _submit(TransferDraft draft) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final cashbook = ref.read(activeCashbookProvider);
      if (cashbook == null) {
        throw Exception('Buku kas tidak ditemukan');
      }

      final wallets = await ref.read(walletsProvider.future);
      if (!hasTransferWalletPair(wallets)) {
        throw Exception('Minimal dua dompet aktif diperlukan');
      }
      final source = _findWallet(wallets, draft.sourceWalletId);
      final destination = _findWallet(wallets, draft.destinationWalletId);
      if (source == null || destination == null) {
        throw Exception('Dompet tidak lagi tersedia');
      }
      if (source.walletId == destination.walletId) {
        throw Exception('Tidak dapat transfer ke dompet yang sama');
      }
      if (!_sourceIsEligible(source, draft)) {
        throw Exception('Saldo dompet asal tidak cukup');
      }

      await ref
          .read(transactionRepositoryProvider)
          .createTransfer(
            cashbookId: cashbook.cashbookId,
            fromWalletId: source.walletId,
            toWalletId: destination.walletId,
            amount: draft.amount,
            notes: draft.notes.trim().isEmpty ? null : draft.notes.trim(),
            transferDate: draft.transferDate,
          );

      ref.invalidate(transfersProvider);
      ref.invalidate(selectedMonthTransfersProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Transfer berhasil ditambahkan')),
      );
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString().toLowerCase();
      final message = raw.contains('saldo')
          ? 'Saldo dompet asal tidak cukup'
          : raw.contains('dua dompet')
          ? 'Transfer membutuhkan minimal dua dompet aktif'
          : 'Gagal menyimpan transfer. Silakan coba lagi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  WalletEntity? _findWallet(List<WalletEntity> wallets, String? walletId) {
    if (walletId == null) return null;
    for (final wallet in wallets) {
      if (wallet.walletId == walletId) return wallet;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(transferDraftProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currentTitle = switch (_currentStep) {
      0 => 'Jumlah',
      1 => 'Dompet asal',
      2 => 'Dompet tujuan',
      3 => 'Tanggal',
      _ => 'Catatan',
    };
    final currentSubtitle = switch (_currentStep) {
      0 => 'Gunakan keypad untuk memasukkan nominal Rupiah.',
      1 => 'Pilih dompet yang saldonya mencukupi.',
      2 => 'Dompet asal otomatis dikecualikan dari pilihan.',
      3 => 'Tanggal otomatis diisi hari ini.',
      _ => 'Catatan bersifat opsional dan boleh dilewati.',
    };
    final canContinue = _canContinue(draft, walletsAsync);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.transferContainer,
          foregroundColor: colorScheme.onTransferColor,
          title: const Text('Tambah Transfer'),
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              tooltip: 'Riwayat transfer',
              onPressed: () => context.push(AppRoutes.transferHistory),
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              SequentialFlowProgress(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                title: currentTitle,
                subtitle: currentSubtitle,
              ),
              Expanded(
                child: PageView(
                  key: const ValueKey('transfer-add-pages'),
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAmountStep(draft),
                    _buildSourceStep(walletsAsync, draft),
                    _buildDestinationStep(walletsAsync, draft),
                    _buildDateStep(draft),
                    _buildNotesStep(draft),
                  ],
                ),
              ),
              SequentialFlowNavigation(
                onBack: _handleBack,
                onContinue: canContinue
                    ? () => _goNext(draft, walletsAsync)
                    : null,
                continueLabel: _currentStep == _totalSteps - 1
                    ? 'Simpan'
                    : 'Lanjut',
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountStep(TransferDraft draft) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('transfer-step-amount'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Semantics(
          liveRegion: true,
          label: 'Nominal ${CurrencyFormatter.format(draft.amount)}',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.transferColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.cardBorder,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.format(draft.amount),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colorScheme.transferColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AmountKeypad(
          canDelete: draft.amount > 0,
          onDigit: (digit) {
            ref.read(transferDraftProvider.notifier).appendDigit(digit);
          },
          onBackspace: () {
            ref.read(transferDraftProvider.notifier).deleteDigit();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: () => context.push(AppRoutes.transferHistory),
            icon: const Icon(Icons.history, size: AppIconSize.small),
            label: const Text('Lihat riwayat transfer'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, AppComponentHeight.interactive),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceStep(
    AsyncValue<List<WalletEntity>> walletsAsync,
    TransferDraft draft,
  ) {
    return _buildWalletSelectionStep(
      key: const ValueKey('transfer-step-source'),
      walletsAsync: walletsAsync,
      draft: draft,
      title: 'Pilih dompet asal',
      subtitle: 'Saldo dompet asal akan berkurang setelah transfer berhasil.',
      isSource: true,
    );
  }

  Widget _buildDestinationStep(
    AsyncValue<List<WalletEntity>> walletsAsync,
    TransferDraft draft,
  ) {
    return _buildWalletSelectionStep(
      key: const ValueKey('transfer-step-destination'),
      walletsAsync: walletsAsync,
      draft: draft,
      title: 'Pilih dompet tujuan',
      subtitle: 'Pilih dompet tujuan yang berbeda dari dompet asal.',
      isSource: false,
    );
  }

  Widget _buildWalletSelectionStep({
    required Key key,
    required AsyncValue<List<WalletEntity>> walletsAsync,
    required TransferDraft draft,
    required String title,
    required String subtitle,
    required bool isSource,
  }) {
    return SelectionStepShell(
      key: key,
      title: title,
      subtitle: subtitle,
      child: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => SelectionStatePanel(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Dompet belum tersedia',
          message: 'Periksa koneksi lalu coba muat ulang dompet.',
          actionLabel: 'Coba lagi',
          onAction: () => ref.invalidate(walletsProvider),
        ),
        data: (wallets) {
          if (!hasTransferWalletPair(wallets)) {
            return SelectionStatePanel(
              icon: Icons.swap_horiz_outlined,
              title: 'Butuh dua dompet aktif',
              message:
                  'Transfer memerlukan minimal dua dompet aktif. Tambahkan dompet lain untuk melanjutkan.',
              actionLabel: 'Buat dompet',
              onAction: _openWalletForm,
            );
          }

          final options = isSource
              ? wallets
              : transferDestinationOptions(wallets, draft.sourceWalletId);
          if (!isSource && options.isEmpty) {
            return const SelectionStatePanel(
              icon: Icons.swap_horiz_outlined,
              title: 'Pilih dompet asal dahulu',
              message:
                  'Kembali ke langkah sebelumnya untuk memilih dompet asal.',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth >= 340 ? 2 : 1;
              final gap = AppSpacing.sm;
              final cardWidth = columnCount == 2
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: options.map((wallet) {
                  final disabledReason =
                      isSource && !_sourceIsEligible(wallet, draft)
                      ? 'Saldo kurang dari nominal'
                      : null;
                  final selectedId = isSource
                      ? draft.sourceWalletId
                      : draft.destinationWalletId;
                  final onTap = disabledReason != null
                      ? null
                      : () {
                          final controller = ref.read(
                            transferDraftProvider.notifier,
                          );
                          if (isSource) {
                            controller.setSourceWallet(wallet.walletId);
                          } else {
                            controller.setDestinationWallet(wallet.walletId);
                          }
                        };
                  return SizedBox(
                    width: cardWidth,
                    child: WalletOptionCard(
                      key: ValueKey('wallet-option-${wallet.walletId}'),
                      wallet: wallet,
                      selected: selectedId == wallet.walletId,
                      disabledReason: disabledReason,
                      onTap: onTap,
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateStep(TransferDraft draft) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('transfer-step-date'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text(
          'Pilih tanggal',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tanggal otomatis diisi hari ini dan tidak boleh melewati hari ini.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          button: true,
          label:
              'Tanggal transfer ${DateFormatter.formatFullDate(draft.transferDate)}',
          child: Material(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.cardBorder,
            child: InkWell(
              key: const ValueKey('transfer-date-control'),
              onTap: _pickDate,
              borderRadius: AppRadius.cardBorder,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppComponentHeight.field,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: colorScheme.transferColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          DateFormatter.formatFullDate(draft.transferDate),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesStep(TransferDraft draft) {
    final colorScheme = Theme.of(context).colorScheme;
    final notesError = Validators.validateNotes(draft.notes);
    return ListView(
      key: const ValueKey('transfer-step-notes'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text(
          'Tambahkan catatan',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Langkah ini boleh dilewati. Catatan membantu mengingat konteks transfer.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _notesController,
          maxLines: 5,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) {
            ref.read(transferDraftProvider.notifier).setNotes(value);
          },
          decoration: const InputDecoration(
            labelText: 'Catatan (opsional)',
            hintText: 'Contoh: pindah dana ke rekening tabungan',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_outlined),
          ).copyWith(errorText: notesError),
        ),
      ],
    );
  }
}
