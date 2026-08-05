import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/models.dart';
import '../../domain/entities/entities.dart';

DateTime _monthStart(DateTime month) => DateTime(month.year, month.month, 1);

DateTime _monthEnd(DateTime month) => DateTime(month.year, month.month + 1, 0);

String _dateOnly(DateTime dateTime) => dateTime.toIso8601String().split('T')[0];

int _sumIntField(List<dynamic> rows, String fieldName) {
  var total = 0;

  for (final row in rows) {
    final value = row[fieldName];
    total += (value as int?) ?? 0;
  }

  return total;
}

/// CashbookRepository - untuk manajemen buku kas
class CashbookRepository {
  final SupabaseClient _client;

  CashbookRepository(this._client);

  /// Buat buku kas baru (set is_default=true untuk buku kas pertama)
  Future<CashbookEntity> createCashbook({
    required String userId,
    required String cashbookName,
    bool setAsDefault = true,
  }) async {
    try {
      final data = await _client
          .from('cashbooks')
          .insert({
            'user_id': userId,
            'cashbook_name': cashbookName,
            'currency': 'IDR',
            'is_default': setAsDefault,
          })
          .select()
          .single();

      return CashbookModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Gagal membuat buku kas: $e');
    }
  }

  /// Update nama buku kas
  Future<CashbookEntity> updateCashbook({
    required String cashbookId,
    required String cashbookName,
  }) async {
    try {
      final data = await _client
          .from('cashbooks')
          .update({'cashbook_name': cashbookName})
          .eq('cashbook_id', cashbookId)
          .select()
          .single();

      return CashbookModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Gagal memperbarui buku kas: $e');
    }
  }

  /// Set sebagai buku kas default
  Future<void> setDefaultCashbook({
    required String userId,
    required String cashbookId,
  }) async {
    try {
      // Unset previous default
      await _client
          .from('cashbooks')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);

      // Set new default
      await _client
          .from('cashbooks')
          .update({'is_default': true})
          .eq('cashbook_id', cashbookId);
    } catch (e) {
      throw Exception('Gagal mengatur buku kas default: $e');
    }
  }

  /// Soft delete buku kas
  Future<void> deleteCashbook(String cashbookId) async {
    try {
      await _client
          .from('cashbooks')
          .update({'is_deleted': true})
          .eq('cashbook_id', cashbookId);
    } catch (e) {
      throw Exception('Gagal menghapus buku kas: $e');
    }
  }

  /// Get total saldo semua dompet dalam buku kas
  Future<int> getTotalBalance(String cashbookId) async {
    try {
      final wallets = await _client
          .from('wallets')
          .select('current_balance')
          .eq('cashbook_id', cashbookId)
          .eq('is_active', true);

      return _sumIntField(wallets as List<dynamic>, 'current_balance');
    } catch (e) {
      return 0;
    }
  }

  /// Get buku kas default/aktif user
  Future<CashbookEntity?> getDefaultCashbook(String userId) async {
    try {
      final data = await _client
          .from('cashbooks')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .eq('is_deleted', false)
          .single();

      return CashbookModel.fromJson(data).toEntity();
    } catch (e) {
      // Jika tidak ada default, return null (akan di-handle di provider)
      return null;
    }
  }

  /// Get buku kas paling awal dibuat (untuk auto-load saat app dibuka)
  Future<CashbookEntity?> getEarliestCashbook(String userId) async {
    try {
      final data = await _client
          .from('cashbooks')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return CashbookModel.fromJson(data).toEntity();
    } catch (e) {
      return null;
    }
  }

  /// Get semua buku kas user (non-deleted)
  Future<List<CashbookEntity>> getUserCashbooks(String userId) async {
    try {
      final data = await _client
          .from('cashbooks')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('is_default', ascending: false);

      return List<CashbookEntity>.from(
        (data as List).map(
          (json) =>
              CashbookModel.fromJson(json as Map<String, dynamic>).toEntity(),
        ),
      );
    } catch (e) {
      throw Exception('Gagal mengambil daftar buku kas: $e');
    }
  }
}

/// WalletRepository - untuk manajemen dompet
class WalletRepository {
  final SupabaseClient _client;

  WalletRepository(this._client);

  /// Buat dompet baru
  Future<WalletEntity> createWallet({
    required String cashbookId,
    required WalletType type,
    required String walletName,
    String? bankName,
    String? accountNumber,
    int initialBalance = 0,
  }) async {
    try {
      final data = await _client
          .from('wallets')
          .insert({
            'cashbook_id': cashbookId,
            'type': type.value,
            'wallet_name': walletName,
            'bank_name': bankName,
            'account_number': accountNumber,
            'initial_balance': initialBalance,
            'current_balance': initialBalance,
            'is_active': true,
          })
          .select()
          .single();

      return WalletModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Gagal membuat dompet: $e');
    }
  }

  /// Update dompet (kecuali balance)
  Future<WalletEntity> updateWallet({
    required String walletId,
    required String walletName,
    String? bankName,
    String? accountNumber,
  }) async {
    try {
      final data = await _client
          .from('wallets')
          .update({
            'wallet_name': walletName,
            'bank_name': bankName,
            'account_number': accountNumber,
          })
          .eq('wallet_id', walletId)
          .select()
          .single();

      return WalletModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Gagal memperbarui dompet: $e');
    }
  }

  /// Soft delete (deactivate) dompet
  Future<void> deactivateWallet(String walletId) async {
    try {
      await _client
          .from('wallets')
          .update({'is_active': false})
          .eq('wallet_id', walletId);
    } catch (e) {
      throw Exception('Gagal menghapus dompet: $e');
    }
  }

  /// Get wallets by cashbook ID
  Future<List<WalletEntity>> getWallets(String cashbookId) async {
    try {
      final data = await _client
          .from('wallets')
          .select()
          .eq('cashbook_id', cashbookId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (data as List)
          .map((e) => WalletModel.fromJson(e).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil dompet: $e');
    }
  }

  /// Get monthly summary (income & expense) untuk wallet
  Future<Map<String, int>> getMonthlySummary({
    required String walletId,
    required DateTime month,
  }) async {
    try {
      final monthStart = _monthStart(month);
      final monthEnd = _monthEnd(month);
      final startDate = _dateOnly(monthStart);
      final endDate = _dateOnly(monthEnd);

      // Income
      final incomeData = await _client
          .from('transactions')
          .select('amount')
          .eq('wallet_id', walletId)
          .eq('type', 'income')
          .eq('is_deleted', false)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate);

      // Expense
      final expenseData = await _client
          .from('transactions')
          .select('amount')
          .eq('wallet_id', walletId)
          .eq('type', 'expense')
          .eq('is_deleted', false)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate);

      return {
        'income': _sumIntField(incomeData as List<dynamic>, 'amount'),
        'expense': _sumIntField(expenseData as List<dynamic>, 'amount'),
      };
    } catch (e) {
      return {'income': 0, 'expense': 0};
    }
  }
}

/// TransactionRepository - untuk manajemen transaksi pemasukan/pengeluaran
class TransactionRepository {
  final SupabaseClient _client;

  // Cache in-memory untuk menyimpan transaksi berdasarkan kombinasi filter
  final Map<String, List<TransactionEntity>> _transactionCache = {};

  TransactionRepository(this._client);

  /// Get daftar transaksi dengan pendekatan Cache-First (Stale-While-Revalidate)
  Stream<List<TransactionEntity>> getTransactionsStream({
    required String cashbookId,
    String? type,
    String? walletId,
    String? categoryId,
    String? startDate,
    String? endDate,
  }) async* {
    // 1. Buat identifier unik untuk cache berdasarkan filter yang sedang aktif
    final cacheKey =
        '${cashbookId}_${type}_${walletId}_${categoryId}_${startDate}_$endDate';

    // 2. Lempar data cache duluan jika ada (UI langsung tampil tanpa loading)
    if (_transactionCache.containsKey(cacheKey)) {
      yield _transactionCache[cacheKey]!;
    }

    // 3. Fetch data terbaru dari Supabase secara diam-diam
    try {
      var query = _client
          .from('transactions')
          .select(
            '*, wallets(wallet_name), categories(category_name, icon, color)',
          )
          .eq('cashbook_id', cashbookId)
          .eq('is_deleted', false);

      if (type != null) query = query.eq('type', type);
      if (walletId != null) query = query.eq('wallet_id', walletId);
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (startDate != null) query = query.gte('transaction_date', startDate);
      if (endDate != null) query = query.lte('transaction_date', endDate);

      final response = await query.order('transaction_date', ascending: false);

      final transactions = (response as List).map((e) {
        return TransactionModel.fromJson(e).toEntity();
      }).toList();

      // 4. Perbarui cache dan lempar data terbaru ke UI
      _transactionCache[cacheKey] = transactions;
      yield transactions;
    } catch (e) {
      // Jika error (misal offline) tapi kita punya cache, biarkan user melihat cache.
      // Jika tidak punya cache, baru lempar error.
      if (!_transactionCache.containsKey(cacheKey)) {
        throw Exception('Gagal mengambil transaksi: $e');
      }
    }
  }

  /// Buat transaksi baru
  Future<TransactionEntity> createTransaction({
    required String cashbookId,
    required String walletId,
    required String categoryId,
    required TransactionType type,
    required int amount,
    String? name,
    String? notes,
    required DateTime transactionDate,
  }) async {
    try {
      final data = await _client
          .from('transactions')
          .insert({
            'cashbook_id': cashbookId,
            'wallet_id': walletId,
            'category_id': categoryId,
            'type': type.value,
            'amount': amount,
            'name': name,
            'notes': notes,
            'transaction_date': _dateOnly(transactionDate),
            'is_deleted': false,
          })
          .select()
          .single();

      return TransactionModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Gagal membuat transaksi: $e');
    }
  }

  /// Update transaksi yang sudah ada
  Future<TransactionEntity> updateTransaction({
    required String transactionId,
    required String walletId,
    required String categoryId,
    required int amount,
    String? name,
    String? notes,
    required DateTime transactionDate,
  }) async {
    try {
      final data = await _client
          .from('transactions')
          .update({
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'name': name,
            'notes': notes,
            'transaction_date': _dateOnly(transactionDate),
          })
          .eq('transaction_id', transactionId)
          .select()
          .single();

      return TransactionModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Gagal memperbarui transaksi: $e');
    }
  }

  /// Hapus transaksi (soft delete)
  Future<void> deleteTransaction(String transactionId) async {
    try {
      // 1. Ambil data transaksi terlebih dahulu
      final trxData = await _client
          .from('transactions')
          .select('wallet_id, amount, type')
          .eq('transaction_id', transactionId)
          .single();

      final walletId = trxData['wallet_id'] as String;
      final amount = trxData['amount'] as int;
      final typeStr = trxData['type'] as String;

      // 2. Ambil saldo wallet saat ini
      final walletData = await _client
          .from('wallets')
          .select('current_balance')
          .eq('wallet_id', walletId)
          .single();

      int currentBalance = (walletData['current_balance'] as int?) ?? 0;

      // 3. Sesuaikan saldo (karena dihapus, kebalikan dari saat dibuat)
      if (typeStr == TransactionType.income.value) {
        currentBalance -= amount;
      } else if (typeStr == TransactionType.expense.value) {
        currentBalance += amount;
      }

      // 4. Update transaksi menjadi terhapus
      await _client
          .from('transactions')
          .update({'is_deleted': true})
          .eq('transaction_id', transactionId);

      // 5. Update saldo wallet
      await _client
          .from('wallets')
          .update({'current_balance': currentBalance})
          .eq('wallet_id', walletId);
    } catch (e) {
      throw Exception('Gagal menghapus transaksi: $e');
    }
  }

  /// Buat transfer antar dompet
  Future<TransferEntity> createTransfer({
    required String cashbookId,
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    String? notes,
    required DateTime transferDate,
  }) async {
    if (fromWalletId == toWalletId) {
      throw Exception('Tidak dapat transfer ke dompet yang sama');
    }
    if (amount <= 0) {
      throw Exception('Jumlah transfer harus lebih dari 0');
    }

    try {
      final fromWallet = await _client
          .from('wallets')
          .select('current_balance')
          .eq('wallet_id', fromWalletId)
          .single();

      final currentBalance = (fromWallet['current_balance'] as int?) ?? 0;
      if (currentBalance < amount) {
        throw Exception('Saldo dompet asal tidak cukup');
      }

      final data = await _client
          .from('transfers')
          .insert({
            'cashbook_id': cashbookId,
            'from_wallet_id': fromWalletId,
            'to_wallet_id': toWalletId,
            'amount': amount,
            'notes': notes,
            'transfer_date': _dateOnly(transferDate),
          })
          .select(
            '*, from_wallet:from_wallet_id(wallet_name), to_wallet:to_wallet_id(wallet_name)',
          )
          .single();

      final transferJson = Map<String, dynamic>.from(data);
      final fromWalletJson =
          transferJson['from_wallet'] as Map<String, dynamic>?;
      final toWalletJson = transferJson['to_wallet'] as Map<String, dynamic>?;
      transferJson['from_wallet_name'] = fromWalletJson?['wallet_name'];
      transferJson['to_wallet_name'] = toWalletJson?['wallet_name'];

      return TransferModel.fromJson(transferJson).toEntity();
    } catch (e) {
      throw Exception('Gagal membuat transfer: $e');
    }
  }

  /// Get daftar transfer per cashbook
  Future<List<TransferEntity>> getTransfersByCashbook(String cashbookId) async {
    try {
      final data = await _client
          .from('transfers')
          .select(
            '*, from_wallet:from_wallet_id(wallet_name), to_wallet:to_wallet_id(wallet_name)',
          )
          .eq('cashbook_id', cashbookId)
          .order('transfer_date', ascending: false);

      return (data as List).map((row) {
        final transferJson = Map<String, dynamic>.from(row);
        final fromWalletJson =
            transferJson['from_wallet'] as Map<String, dynamic>?;
        final toWalletJson = transferJson['to_wallet'] as Map<String, dynamic>?;
        transferJson['from_wallet_name'] = fromWalletJson?['wallet_name'];
        transferJson['to_wallet_name'] = toWalletJson?['wallet_name'];
        return TransferModel.fromJson(transferJson).toEntity();
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil transfer: $e');
    }
  }

  /// Get monthly summary (income & expense) untuk laporan
  Future<Map<String, int>> getMonthlySummaryForReport({
    required String cashbookId,
    required DateTime month,
  }) async {
    try {
      final monthStart = _monthStart(month);
      final monthEnd = _monthEnd(month);
      final startDate = _dateOnly(monthStart);
      final endDate = _dateOnly(monthEnd);

      final response = await _client
          .from('transactions')
          .select('type, amount')
          .eq('cashbook_id', cashbookId)
          .eq('is_deleted', false)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate);

      int income = 0;
      int expense = 0;
      for (final tx in response as List) {
        final amount = (tx['amount'] as int?) ?? 0;
        if (tx['type'] == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }
      return {'income': income, 'expense': expense};
    } catch (e) {
      return {'income': 0, 'expense': 0};
    }
  }

  /// Get breakdown per kategori untuk pie chart laporan
  /// Returns list: {categoryId, categoryName, icon, color, amount}
  Future<List<Map<String, dynamic>>> getCategoryBreakdownByMonth({
    required String cashbookId,
    required DateTime month,
    required TransactionType transactionType,
  }) async {
    try {
      final monthStart = _monthStart(month);
      final monthEnd = _monthEnd(month);
      final startDate = _dateOnly(monthStart);
      final endDate = _dateOnly(monthEnd);

      final response = await _client
          .from('transactions')
          .select('amount, category_id, categories(category_name, icon, color)')
          .eq('cashbook_id', cashbookId)
          .eq('type', transactionType.value)
          .eq('is_deleted', false)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate);

      // Aggregate by category
      final Map<String, Map<String, dynamic>> aggregated = {};
      for (final tx in response as List) {
        final categoryId = (tx['category_id'] as String?) ?? 'uncategorized';
        final amount = (tx['amount'] as int?) ?? 0;
        final categoryData = tx['categories'] as Map<String, dynamic>?;
        final categoryName =
            (categoryData?['category_name'] as String?) ?? 'Lainnya';
        final icon = (categoryData?['icon'] as String?) ?? 'lainnya';
        final color = (categoryData?['color'] as String?) ?? '#9E9E9E';

        if (aggregated.containsKey(categoryId)) {
          aggregated[categoryId]!['amount'] =
              (aggregated[categoryId]!['amount'] as int) + amount;
        } else {
          aggregated[categoryId] = {
            'categoryId': categoryId,
            'categoryName': categoryName,
            'icon': icon,
            'color': color,
            'amount': amount,
          };
        }
      }

      final result = aggregated.values.toList();
      result.sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Get data trend 12 bulan untuk bar chart laporan
  /// Returns list per bulan: {month: int, year: int, income: int, expense: int}
  Future<List<Map<String, int>>> getYearlyTrendData({
    required String cashbookId,
    required int year,
  }) async {
    try {
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year, 12, 31);

      final response = await _client
          .from('transactions')
          .select('type, amount, transaction_date')
          .eq('cashbook_id', cashbookId)
          .eq('is_deleted', false)
          .gte('transaction_date', yearStart.toIso8601String().split('T')[0])
          .lte('transaction_date', yearEnd.toIso8601String().split('T')[0]);

      // Initialize all 12 months
      final Map<int, Map<String, int>> monthly = {
        for (int m = 1; m <= 12; m++)
          m: {'month': m, 'year': year, 'income': 0, 'expense': 0},
      };

      for (final tx in response as List) {
        final dateStr = tx['transaction_date'] as String;
        final month = int.parse(dateStr.split('-')[1]);
        final amount = (tx['amount'] as int?) ?? 0;

        if (tx['type'] == 'income') {
          monthly[month]!['income'] = monthly[month]!['income']! + amount;
        } else {
          monthly[month]!['expense'] = monthly[month]!['expense']! + amount;
        }
      }

      return monthly.values.toList();
    } catch (e) {
      return [
        for (int m = 1; m <= 12; m++)
          {'month': m, 'year': year, 'income': 0, 'expense': 0},
      ];
    }
  }
}

/// SettingsRepository - aksi pengaturan akun dan aplikasi
class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository(this._client);

  /// Update nama tampilan user pada tabel users
  Future<UserEntity> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    try {
      final data = await _client
          .from('users')
          .update({'display_name': displayName})
          .eq('user_id', userId)
          .select()
          .single();

      return UserModel.fromJson(data).toEntity();
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  /// Update password user yang sedang login
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('Gagal mengubah password: $e');
    }
  }

  /// Mengirim email pemulihan password untuk user yang belum bisa login.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Gagal mengirim email pemulihan password: $e');
    }
  }

  /// Logout user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Gagal logout: $e');
    }
  }
}
