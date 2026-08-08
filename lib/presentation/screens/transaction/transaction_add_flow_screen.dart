import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../../state/sequential_add_state.dart';
import '../../widgets/sequential_flow_widgets.dart';

/// Five-step add flow for a new income or expense.
class TransactionAddFlowScreen extends ConsumerStatefulWidget {
  final TransactionType type;

  const TransactionAddFlowScreen({super.key, required this.type});

  @override
  ConsumerState<TransactionAddFlowScreen> createState() =>
      _TransactionAddFlowScreenState();
}

class _TransactionAddFlowScreenState
    extends ConsumerState<TransactionAddFlowScreen> {
  static const _totalSteps = 5;

  late final PageController _pageController;
  late final TextEditingController _notesController;
  int _currentStep = 0;
  bool _isSubmitting = false;

  bool get _isIncome => widget.type == TransactionType.income;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _notesController = TextEditingController(
      text: ref.read(transactionDraftProvider).notes,
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

  void _setNotes(String notes) {
    ref.read(transactionDraftProvider.notifier).setNotes(notes);
  }

  bool _walletIsEligible(WalletEntity wallet, TransactionDraft draft) {
    if (_isIncome) return true;
    return wallet.currentBalance >= draft.amount;
  }

  bool _canContinue(
    TransactionDraft draft,
    AsyncValue<List<CategoryEntity>> categoriesAsync,
    AsyncValue<List<WalletEntity>> walletsAsync,
  ) {
    switch (_currentStep) {
      case 0:
        return Validators.validateAmountValue(draft.amount) == null;
      case 1:
        return categoriesAsync.whenOrNull(
              data: (categories) => categories.any(
                (category) =>
                    category.type == widget.type &&
                    category.categoryId == draft.categoryId,
              ),
            ) ??
            false;
      case 2:
        return walletsAsync.whenOrNull(
              data: (wallets) {
                for (final wallet in wallets) {
                  if (wallet.walletId == draft.walletId) {
                    return _walletIsEligible(wallet, draft);
                  }
                }
                return false;
              },
            ) ??
            false;
      case 3:
        return Validators.validateTransactionDate(draft.transactionDate) ==
            null;
      case 4:
        return Validators.validateNotes(draft.notes) == null;
      default:
        return false;
    }
  }

  void _goNext(
    TransactionDraft draft,
    AsyncValue<List<CategoryEntity>> categoriesAsync,
    AsyncValue<List<WalletEntity>> walletsAsync,
  ) {
    if (_isSubmitting) return;
    if (!_canContinue(draft, categoriesAsync, walletsAsync)) {
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
      1 => 'Pilih kategori terlebih dahulu',
      2 => 'Pilih dompet yang saldonya mencukupi',
      3 => 'Pilih tanggal yang valid',
      _ =>
        Validators.validateNotes(ref.read(transactionDraftProvider).notes) ??
            'Lengkapi catatan',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final draft = ref.read(transactionDraftProvider);
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 100),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && mounted) {
      ref.read(transactionDraftProvider.notifier).setDate(picked);
    }
  }

  Future<void> _submit(TransactionDraft draft) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final cashbook = ref.read(activeCashbookProvider);
      if (cashbook == null) {
        throw Exception('Buku kas tidak ditemukan');
      }

      final categories = await ref.read(
        categoriesProvider(cashbook.cashbookId).future,
      );
      final wallets = await ref.read(walletsProvider.future);
      final category = _findCategory(categories, draft.categoryId);
      final wallet = _findWallet(wallets, draft.walletId);

      if (category == null || category.type != widget.type) {
        throw Exception('Kategori tidak tersedia');
      }
      if (wallet == null || !_walletIsEligible(wallet, draft)) {
        throw Exception('Saldo dompet tidak cukup');
      }

      await ref
          .read(transactionRepositoryProvider)
          .createTransaction(
            cashbookId: cashbook.cashbookId,
            walletId: wallet.walletId,
            categoryId: category.categoryId,
            type: widget.type,
            amount: draft.amount,
            // The add flow has no separate name field. Existing list/detail
            // consumers safely fall back to category/placeholder when null.
            name: null,
            notes: draft.notes.trim().isEmpty ? null : draft.notes.trim(),
            transactionDate: draft.transactionDate,
          );

      ref.invalidate(transactionsProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(futureTransactionProjectionProvider);
      ref.invalidate(cashbookBalanceProvider(cashbook.cashbookId));

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isIncome
                ? 'Pemasukan berhasil ditambahkan'
                : 'Pengeluaran berhasil ditambahkan',
          ),
          backgroundColor: Theme.of(context).colorScheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString().toLowerCase();
      final message = raw.contains('saldo')
          ? 'Saldo dompet tidak cukup untuk transaksi ini'
          : 'Gagal menyimpan transaksi. Silakan coba lagi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  CategoryEntity? _findCategory(
    List<CategoryEntity> categories,
    String? categoryId,
  ) {
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.categoryId == categoryId) return category;
    }
    return null;
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
    final draft = ref.watch(transactionDraftProvider);
    final activeCashbook = ref.watch(activeCashbookProvider);
    final categoriesAsync = activeCashbook == null
        ? AsyncValue.data(<CategoryEntity>[])
        : ref.watch(categoriesProvider(activeCashbook.cashbookId));
    final walletsAsync = ref.watch(walletsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final flowColor = _isIncome
        ? colorScheme.incomeColor
        : colorScheme.expenseColor;
    final currentTitle = switch (_currentStep) {
      0 => 'Jumlah',
      1 => 'Kategori',
      2 => 'Dompet sumber',
      3 => 'Tanggal',
      _ => 'Catatan',
    };
    final currentSubtitle = switch (_currentStep) {
      0 => 'Gunakan keypad untuk memasukkan nominal Rupiah.',
      1 => 'Pilih kategori yang paling sesuai.',
      2 => 'Tentukan dompet tempat transaksi ini dicatat.',
      3 => 'Tanggal dapat dijadwalkan untuk hari mendatang.',
      _ => 'Catatan bersifat opsional dan boleh dilewati.',
    };
    final canContinue = _canContinue(draft, categoriesAsync, walletsAsync);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: _isIncome
              ? colorScheme.incomeContainer
              : colorScheme.expenseContainer,
          foregroundColor: _isIncome
              ? colorScheme.onIncomeColor
              : colorScheme.onExpenseColor,
          title: Text(_isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran'),
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back),
          ),
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
                  key: const ValueKey('transaction-add-pages'),
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAmountStep(draft, flowColor),
                    _buildCategoryStep(categoriesAsync),
                    _buildWalletStep(walletsAsync, draft),
                    _buildDateStep(draft, flowColor),
                    _buildNotesStep(draft, flowColor),
                  ],
                ),
              ),
              SequentialFlowNavigation(
                onBack: _handleBack,
                onContinue: canContinue
                    ? () => _goNext(draft, categoriesAsync, walletsAsync)
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

  Widget _buildAmountStep(TransactionDraft draft, Color flowColor) {
    return ListView(
      key: const ValueKey('transaction-step-amount'),
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
              color: flowColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.cardBorder,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.format(draft.amount),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: flowColor,
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
            ref.read(transactionDraftProvider.notifier).appendDigit(digit);
          },
          onBackspace: () {
            ref.read(transactionDraftProvider.notifier).deleteDigit();
          },
        ),
      ],
    );
  }

  Future<void> _openCategoryPicker(String? selectedCategoryId) async {
    final cashbook = ref.read(activeCashbookProvider);
    if (cashbook == null) return;
    final category = await showModalBottomSheet<CategoryEntity>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.prominentTopBorder,
      ),
      builder: (_) => CategoryPickerSheet(
        cashbookId: cashbook.cashbookId,
        type: widget.type,
        selectedId: selectedCategoryId,
      ),
    );
    if (category != null && mounted) {
      ref
          .read(transactionDraftProvider.notifier)
          .setCategory(category.categoryId);
    }
  }

  Widget _buildCategoryStep(AsyncValue<List<CategoryEntity>> categoriesAsync) {
    final draft = ref.watch(transactionDraftProvider);
    return SelectionStepShell(
      key: const ValueKey('transaction-step-category'),
      title: 'Pilih kategori',
      subtitle: 'Kategori membantu merangkum transaksi di laporan.',
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => SelectionStatePanel(
          icon: Icons.cloud_off_outlined,
          title: 'Kategori belum tersedia',
          message: 'Periksa koneksi lalu coba muat ulang kategori.',
          actionLabel: 'Coba lagi',
          onAction: () {
            final cashbook = ref.read(activeCashbookProvider);
            if (cashbook != null) {
              ref.invalidate(categoriesProvider(cashbook.cashbookId));
            }
          },
        ),
        data: (allCategories) {
          final categories = allCategories
              .where((category) => category.type == widget.type)
              .toList();
          if (categories.isEmpty) {
            return SelectionStatePanel(
              icon: Icons.category_outlined,
              title: 'Belum ada kategori',
              message: 'Kategori untuk tipe transaksi ini belum tersedia.',
              actionLabel: 'Tambah kategori',
              onAction: () => _openCategoryPicker(draft.categoryId),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const ValueKey('transaction-add-category-action'),
                  onPressed: () => _openCategoryPicker(draft.categoryId),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah kategori'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, AppComponentHeight.interactive),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 280 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisExtent: 124,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return CategoryOptionTile(
                        key: ValueKey('category-option-${category.categoryId}'),
                        category: category,
                        selected: category.categoryId == draft.categoryId,
                        onTap: () {
                          ref
                              .read(transactionDraftProvider.notifier)
                              .setCategory(category.categoryId);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalletStep(
    AsyncValue<List<WalletEntity>> walletsAsync,
    TransactionDraft draft,
  ) {
    return SelectionStepShell(
      key: const ValueKey('transaction-step-wallet'),
      title: 'Pilih dompet sumber',
      subtitle: _isIncome
          ? 'Uang masuk akan dicatat ke dompet yang dipilih.'
          : 'Dompet dengan saldo kurang akan dinonaktifkan.',
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
          if (wallets.isEmpty) {
            return SelectionStatePanel(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Belum ada dompet',
              message: 'Buat dompet terlebih dahulu untuk mencatat transaksi.',
              actionLabel: 'Buat dompet',
              onAction: () async {
                await context.push('/wallets/form');
                if (mounted) ref.invalidate(walletsProvider);
              },
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
                children: wallets.map((wallet) {
                  final disabledReason = _walletIsEligible(wallet, draft)
                      ? null
                      : 'Saldo kurang dari nominal';
                  return SizedBox(
                    width: cardWidth,
                    child: WalletOptionCard(
                      key: ValueKey('wallet-option-${wallet.walletId}'),
                      wallet: wallet,
                      selected: wallet.walletId == draft.walletId,
                      disabledReason: disabledReason,
                      onTap: disabledReason == null
                          ? () => ref
                                .read(transactionDraftProvider.notifier)
                                .setWallet(wallet.walletId)
                          : null,
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

  Widget _buildDateStep(TransactionDraft draft, Color flowColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('transaction-step-date'),
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
          'Tanggal otomatis diisi hari ini dan dapat dijadwalkan untuk hari mendatang.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          button: true,
          label:
              'Tanggal transaksi ${DateFormatter.formatFullDate(draft.transactionDate)}',
          child: Material(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.cardBorder,
            child: InkWell(
              key: const ValueKey('transaction-date-control'),
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
                      Icon(Icons.calendar_today_outlined, color: flowColor),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          DateFormatter.formatFullDate(draft.transactionDate),
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

  Widget _buildNotesStep(TransactionDraft draft, Color flowColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final notesError = Validators.validateNotes(draft.notes);
    return ListView(
      key: const ValueKey('transaction-step-notes'),
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
          'Langkah ini boleh dilewati. Catatan membantu mengingat konteks transaksi.',
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
          onChanged: _setNotes,
          decoration: InputDecoration(
            labelText: 'Catatan (opsional)',
            hintText: 'Contoh: pembayaran rutin bulan ini',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_outlined, color: flowColor),
            errorText: notesError,
          ),
        ),
      ],
    );
  }
}
