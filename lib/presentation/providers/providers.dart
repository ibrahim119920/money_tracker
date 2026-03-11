import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/models.dart';
import '../../data/repositories/cashbook_wallet_repository.dart';
import '../../domain/entities/entities.dart';

// ============================================================================
// CORE PROVIDERS
// ============================================================================

/// Supabase Client Provider - Base provider untuk semua fitur
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
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

// ============================================================================
// SETUP / ONBOARDING PROVIDERS
// ============================================================================

/// Flag untuk mencegah router redirect selama proses setup pertama kali (register onboarding)
final setupInProgressProvider = StateProvider<bool>((ref) => false);

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
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('cashbooks')
        .select()
        .order('created_at', ascending: false);

    final cashbooks = (response as List).map(
      (e) => CashbookModel.fromJson(e).toEntity(),
    );
    return cashbooks.toList();
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

  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('wallets')
        .select()
        .eq('cashbook_id', activeCashbook.cashbookId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    final wallets = (response as List).map(
      (e) => WalletModel.fromJson(e).toEntity(),
    );
    return wallets.toList();
  } catch (e) {
    throw Exception('Failed to fetch wallets: $e');
  }
});

/// Total Balance Provider - Total saldo semua dompet di cashbook aktif
final totalBalanceProvider = FutureProvider<int>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);

  int total = 0;
  for (final wallet in wallets) {
    total += wallet.currentBalance;
  }
  return total;
});

// ============================================================================
// CATEGORY PROVIDERS
// ============================================================================

/// Categories Provider - Kategorisasi transaksi (system + user)
final categoriesProvider = FutureProvider.family<List<CategoryEntity>, String?>(
  (ref, cashbookId) async {
    final client = ref.watch(supabaseClientProvider);

    try {
      final response = await client
          .from('categories')
          .select()
          .or('cashbook_id.is.null,cashbook_id.eq.$cashbookId')
          .order('sort_order', ascending: true);

      final categories = (response as List).map(
        (e) => CategoryModel.fromJson(e).toEntity(),
      );
      return categories.toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
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

/// Transactions Provider - Daftar transaksi dengan filter
final transactionsProvider = FutureProvider<List<TransactionEntity>>((
  ref,
) async {
  final activeCashbook = ref.watch(activeCashbookProvider);
  final filter = ref.watch(transactionFilterProvider);
  final client = ref.watch(supabaseClientProvider);

  if (activeCashbook == null) return [];

  try {
    var query = client
        .from('transactions')
        .select(
          '*, wallets(wallet_name), categories(category_name, icon, color)',
        )
        .eq('cashbook_id', activeCashbook.cashbookId)
        .eq('is_deleted', false);

    if (filter.type != null) {
      query = query.eq('type', filter.type!.value);
    }

    if (filter.walletId != null) {
      query = query.eq('wallet_id', filter.walletId!);
    }

    if (filter.categoryId != null) {
      query = query.eq('category_id', filter.categoryId!);
    }

    if (filter.startDate != null) {
      query = query.gte(
        'transaction_date',
        filter.startDate!.toIso8601String().split('T')[0],
      );
    }

    if (filter.endDate != null) {
      query = query.lte(
        'transaction_date',
        filter.endDate!.toIso8601String().split('T')[0],
      );
    }

    final response = await query.order('transaction_date', ascending: false);

    final transactions = (response as List).map((e) {
      final model = TransactionModel.fromJson(e);
      return model.toEntity();
    });
    return transactions.toList();
  } catch (e) {
    throw Exception('Failed to fetch transactions: $e');
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
  final client = ref.watch(supabaseClientProvider);

  if (activeCashbook == null) {
    return {'income': 0, 'expense': 0};
  }

  try {
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    // Income
    final incomeResponse = await client
        .from('transactions')
        .select('amount')
        .eq('cashbook_id', activeCashbook.cashbookId)
        .eq('type', 'income')
        .eq('is_deleted', false)
        .gte('transaction_date', monthStart.toIso8601String().split('T')[0])
        .lte('transaction_date', monthEnd.toIso8601String().split('T')[0]);

    int totalIncome = 0;
    for (final tx in incomeResponse as List) {
      totalIncome += (tx['amount'] as int?) ?? 0;
    }

    // Expense
    final expenseResponse = await client
        .from('transactions')
        .select('amount')
        .eq('cashbook_id', activeCashbook.cashbookId)
        .eq('type', 'expense')
        .eq('is_deleted', false)
        .gte('transaction_date', monthStart.toIso8601String().split('T')[0])
        .lte('transaction_date', monthEnd.toIso8601String().split('T')[0]);

    int totalExpense = 0;
    for (final tx in expenseResponse as List) {
      totalExpense += (tx['amount'] as int?) ?? 0;
    }

    return {'income': totalIncome, 'expense': totalExpense};
  } catch (e) {
    throw Exception('Failed to fetch monthly summary: $e');
  }
});

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
  final client = ref.watch(supabaseClientProvider);

  if (activeCashbook == null) return [];

  try {
    final response = await client
        .from('transfers')
        .select(
          '*, from_wallets:from_wallet_id(wallet_name), to_wallets:to_wallet_id(wallet_name)',
        )
        .eq('cashbook_id', activeCashbook.cashbookId)
        .order('transfer_date', ascending: false);

    final transfers = (response as List).map((e) {
      final model = TransferModel.fromJson(e);
      return model.toEntity();
    });
    return transfers.toList();
  } catch (e) {
    throw Exception('Failed to fetch transfers: $e');
  }
});
