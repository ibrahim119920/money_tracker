import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/models.dart';
import '../../data/repositories/cashbook_wallet_repository.dart';
import '../../domain/entities/entities.dart';
import '../state/sequential_add_state.dart';

// ============================================================================
// CORE PROVIDERS
// ============================================================================

/// Supabase Client Provider - Base provider untuk semua fitur
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// SharedPreferences Provider
final sharedPreferencesProvider = Provider<Future<SharedPreferences>>((ref) {
  return SharedPreferences.getInstance();
});

/// Cashbook Repository Provider
final cashbookRepositoryProvider = Provider<CashbookRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CashbookRepository(client);
});

/// Wallet Repository Provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WalletRepository(client);
});

/// Transaction Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TransactionRepository(client);
});

/// Settings Repository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SettingsRepository(client);
});

/// Theme mode aplikasi (runtime state with persistence)
final appThemeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ThemeModeNotifier(prefs);
    });

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Future<SharedPreferences> _prefsFuture;
  SharedPreferences? _prefs;

  ThemeModeNotifier(this._prefsFuture) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      _prefs = await _prefsFuture;
      final themeIndex = _prefs?.getInt('theme_mode') ?? 0;
      state = ThemeMode.values[themeIndex];
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs?.setInt('theme_mode', mode.index);
  }
}

// ============================================================================
// SETUP / ONBOARDING PROVIDERS
// ============================================================================

/// Flag untuk mencegah router redirect selama proses setup pertama kali (register onboarding)
final setupInProgressProvider = StateProvider<bool>((ref) => false);

// ============================================================================
// SEQUENTIAL ADD FLOW DRAFT PROVIDERS
// ============================================================================

/// Draft for the income/expense sequential add flow.
final transactionDraftProvider =
    AutoDisposeNotifierProvider<TransactionDraftController, TransactionDraft>(
      TransactionDraftController.new,
    );

/// Draft for the transfer sequential add flow.
final transferDraftProvider =
    AutoDisposeNotifierProvider<TransferDraftController, TransferDraft>(
      TransferDraftController.new,
    );

// ============================================================================
// AUTH PROVIDERS
// ============================================================================

/// Auth State Provider - Stream dari state user auth
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Current User Provider - Get user saat ini
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;

  if (user == null) return null;

  try {
    final response = await client
        .from('users')
        .select()
        .eq('user_id', user.id)
        .single();

    return UserModel.fromJson(response).toEntity();
  } catch (e) {
    return null;
  }
});

// ============================================================================
// CASHBOOK PROVIDERS
// ============================================================================

/// Active Cashbook Provider - Cashbook yang sedang dipilih
final activeCashbookProvider = StateProvider<CashbookEntity?>((ref) => null);

/// Cashbooks Provider - Daftar semua cashbook user
final cashbooksProvider = FutureProvider<List<CashbookEntity>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];

  final repository = ref.watch(cashbookRepositoryProvider);

  try {
    return repository.getUserCashbooks(currentUser.userId);
  } catch (e) {
    throw Exception('Failed to fetch cashbooks: $e');
  }
});

/// Default Cashbook Provider - Auto-load buku kas default & set ke activeCashbookProvider
final defaultCashbookProvider = FutureProvider<CashbookEntity?>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return null;

  final repository = ref.watch(cashbookRepositoryProvider);
  final defaultCashbook = await repository.getEarliestCashbook(
    currentUser.userId,
  );

  // Auto-set ke active cashbook jika ditemukan
  if (defaultCashbook != null) {
    ref.read(activeCashbookProvider.notifier).state = defaultCashbook;
  }

  return defaultCashbook;
});

/// Needs Onboarding Provider - Check apakah user memerlukan setup (tidak punya cashbook/wallet)
final needsOnboardingProvider = FutureProvider<bool>((ref) async {
  final cashbooks = await ref
      .watch(cashbooksProvider.future)
      .catchError((_) => <CashbookEntity>[]);
  final wallets = await ref
      .watch(walletsProvider.future)
      .catchError((_) => <WalletEntity>[]);

  // User memerlukan onboarding jika tidak punya cashbook atau tidak punya wallet
  return cashbooks.isEmpty || wallets.isEmpty;
});

// ============================================================================
// WALLET PROVIDERS
// ============================================================================

/// Wallets Provider - Daftar dompet di cashbook aktif
final walletsProvider = FutureProvider<List<WalletEntity>>((ref) async {
  final activeCashbook = ref.watch(activeCashbookProvider);

  if (activeCashbook == null) return [];

  final repository = ref.watch(walletRepositoryProvider);

  try {
    return repository.getWallets(activeCashbook.cashbookId);
  } catch (e) {
    throw Exception('Failed to fetch wallets: $e');
  }
});

/// Total Balance Provider - Total saldo semua dompet di cashbook aktif
final totalBalanceProvider = FutureProvider<int>((ref) async {
  final activeCashbook = ref.watch(activeCashbookProvider);
  if (activeCashbook == null) return 0;

  final repository = ref.watch(cashbookRepositoryProvider);
  return repository.getTotalBalance(activeCashbook.cashbookId);
});

/// Stable, cacheable balance for a cashbook row in the cashbook list.
///
/// A named family keeps a list item from constructing a fresh provider during
/// every rebuild, which previously left the subtitle at "Menghitung...".
final cashbookBalanceProvider = FutureProvider.family<int, String>((
  ref,
  cashbookId,
) async {
  final repository = ref.watch(cashbookRepositoryProvider);
  return repository.getTotalBalance(cashbookId);
});

/// Current and end-of-month balances after removing scheduled transactions
/// from trigger-updated wallet totals.
final futureTransactionProjectionProvider =
    FutureProvider<FutureTransactionProjection>((ref) async {
      final activeCashbook = ref.watch(activeCashbookProvider);
      if (activeCashbook == null) {
        return const FutureTransactionProjection(
          currentBalance: 0,
          endOfCurrentMonthBalance: 0,
          futureNet: 0,
          currentMonthFutureNet: 0,
          futureTransactionCount: 0,
        );
      }

      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getFutureTransactionProjection(
        cashbookId: activeCashbook.cashbookId,
      );
    });

// ============================================================================
// CATEGORY PROVIDERS
// ============================================================================

/// Categories Provider - Kategorisasi transaksi (system + user)
final categoriesProvider = FutureProvider.family<List<CategoryEntity>, String?>(
  (ref, cashbookId) async {
    if (cashbookId == null) return [];
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getCategories(cashbookId);
  },
);

// ============================================================================
// TRANSACTION FILTER & PROVIDERS
// ============================================================================

/// Transaction Filter State
class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? type;
  final String? categoryId;
  final String? walletId;

  TransactionFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.categoryId,
    this.walletId,
  });

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? categoryId,
    String? walletId,
  }) {
    return TransactionFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
    );
  }

  /// Factory untuk filter bulan aktif
  factory TransactionFilter.thisMonth() {
    final now = DateTime.now();
    return TransactionFilter(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
    );
  }
}

/// Transaction Filter Provider
final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  return TransactionFilter.thisMonth();
});

/// Transactions Provider - Menggunakan StreamProvider untuk Cache-First
final transactionsProvider = StreamProvider<List<TransactionEntity>>((ref) {
  final activeCashbook = ref.watch(activeCashbookProvider);
  final filter = ref.watch(transactionFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  if (activeCashbook == null) return const Stream.empty();

  // Panggil stream dari repository dengan mem-passing nilai filter
  return repository.getTransactionsStream(
    cashbookId: activeCashbook.cashbookId,
    type: filter.type?.value,
    walletId: filter.walletId,
    categoryId: filter.categoryId,
    startDate: DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    ).toIso8601String().split('T')[0],
    endDate: DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).toIso8601String().split('T')[0],
  );
});

/// Item terkelompok untuk daftar transaksi di UI.
class TransactionListItem {
  final bool isHeader;
  final DateTime? date;
  final TransactionEntity? transaction;

  const TransactionListItem._({
    required this.isHeader,
    this.date,
    this.transaction,
  });

  factory TransactionListItem.header(DateTime date) {
    return TransactionListItem._(isHeader: true, date: date);
  }

  factory TransactionListItem.transaction(TransactionEntity transaction) {
    return TransactionListItem._(isHeader: false, transaction: transaction);
  }
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

List<TransactionListItem> _buildTransactionListItems(
  List<TransactionEntity> transactions,
) {
  final items = <TransactionListItem>[];
  DateTime? currentDate;

  for (final transaction in transactions) {
    final transactionDate = DateTime(
      transaction.transactionDate.year,
      transaction.transactionDate.month,
      transaction.transactionDate.day,
    );

    if (currentDate == null || !_isSameDay(transactionDate, currentDate)) {
      currentDate = transactionDate;
      items.add(TransactionListItem.header(transactionDate));
    }

    items.add(TransactionListItem.transaction(transaction));
  }

  return items;
}

/// Transaction List Items Provider - Derive data yang sudah dikelompokkan (support Stream)
final transactionListItemsProvider =
    Provider<AsyncValue<List<TransactionListItem>>>((ref) {
      // Watch StreamProvider, otomatis mendapatkan state AsyncValue
      final transactionsAsync = ref.watch(transactionsProvider);

      // Transformasi List<TransactionEntity> menjadi List<TransactionListItem>
      return transactionsAsync.whenData((transactions) {
        return _buildTransactionListItems(transactions);
      });
    });

/// Transaction Detail Provider - Detail transaksi by ID (dengan joined wallet & kategori)
final transactionDetailProvider =
    FutureProvider.family<TransactionEntity, String>((
      ref,
      transactionId,
    ) async {
      final client = ref.watch(supabaseClientProvider);

      try {
        final response = await client
            .from('transactions')
            .select(
              '*, wallets(wallet_name), categories(category_name, icon, color)',
            )
            .eq('transaction_id', transactionId)
            .eq('is_deleted', false)
            .single();

        return TransactionModel.fromJson(response).toEntity();
      } catch (e) {
        throw Exception('Failed to fetch transaction detail: $e');
      }
    });

/// Monthly Summary Provider - Ringkasan income/expense per bulan
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthlySummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final activeCashbook = ref.watch(activeCashbookProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  if (activeCashbook == null) {
    return {'income': 0, 'expense': 0};
  }

  try {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getMonthlySummaryForReport(
      cashbookId: activeCashbook.cashbookId,
      month: selectedMonth,
    );
  } catch (e) {
    throw Exception('Failed to fetch monthly summary: $e');
  }
});

/// The fourth history segment is independent from income/expense filtering.
enum TransactionHistorySegment { all, income, expense, transfer }

final transactionHistorySegmentProvider =
    StateProvider<TransactionHistorySegment>(
      (ref) => TransactionHistorySegment.all,
    );

// ============================================================================
// REPORT PROVIDERS
// ============================================================================

/// Bulan yang dipilih di halaman laporan
final reportMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Summary income/expense untuk bulan tertentu di laporan
final reportMonthlySummaryProvider =
    FutureProvider.family<Map<String, int>, DateTime>((ref, month) async {
      final activeCashbook = ref.watch(activeCashbookProvider);
      if (activeCashbook == null) return {'income': 0, 'expense': 0};

      final repo = ref.watch(transactionRepositoryProvider);
      return repo.getMonthlySummaryForReport(
        cashbookId: activeCashbook.cashbookId,
        month: month,
      );
    });

/// Category breakdown untuk pie chart laporan
/// Param: (cashbookId, month, transactionType sebagai string 'income'/'expense')
final reportCategoryBreakdownProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({String cashbookId, DateTime month, TransactionType transactionType})
    >((ref, param) async {
      final repo = ref.watch(transactionRepositoryProvider);
      return repo.getCategoryBreakdownByMonth(
        cashbookId: param.cashbookId,
        month: param.month,
        transactionType: param.transactionType,
      );
    });

/// Data trend 12 bulan untuk bar chart laporan
/// Param: (cashbookId, year)
final reportYearlyTrendProvider =
    FutureProvider.family<
      List<Map<String, int>>,
      ({String cashbookId, int year})
    >((ref, param) async {
      final repo = ref.watch(transactionRepositoryProvider);
      return repo.getYearlyTrendData(
        cashbookId: param.cashbookId,
        year: param.year,
      );
    });

// ============================================================================
// TRANSFER PROVIDERS
// ============================================================================

/// Transfers Provider - Daftar transfer di cashbook aktif
final transfersProvider = FutureProvider<List<TransferEntity>>((ref) async {
  final activeCashbook = ref.watch(activeCashbookProvider);

  if (activeCashbook == null) return [];

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransfersByCashbook(activeCashbook.cashbookId);
});

/// Transfers limited to the month selected in transaction history.
final selectedMonthTransfersProvider = FutureProvider<List<TransferEntity>>((
  ref,
) async {
  final activeCashbook = ref.watch(activeCashbookProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  if (activeCashbook == null) return [];

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransfersByCashbook(
    activeCashbook.cashbookId,
    month: selectedMonth,
  );
});
