/// Enum untuk tipe dompet
enum WalletType {
  cash('cash', 'Tunai'),
  bankAcc('bank_acc', 'Rekening Bank'),
  eWallet('ewallet', 'E-Wallet');

  const WalletType(this.value, this.label);
  final String value;
  final String label;

  static WalletType? fromString(String value) {
    try {
      return WalletType.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}

/// Enum untuk tipe transaksi
enum TransactionType {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran');

  const TransactionType(this.value, this.label);
  final String value;
  final String label;

  static TransactionType? fromString(String value) {
    try {
      return TransactionType.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}

/// Enum untuk frekuensi transaksi berulang
enum RecurringFrequency {
  daily('daily', 'Harian'),
  weekly('weekly', 'Mingguan'),
  monthly('monthly', 'Bulanan'),
  yearly('yearly', 'Tahunan');

  const RecurringFrequency(this.value, this.label);
  final String value;
  final String label;

  static RecurringFrequency? fromString(String value) {
    try {
      return RecurringFrequency.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}

/// User Entity - Pure Dart class
class UserEntity {
  final String userId;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  UserEntity({
    required this.userId,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  @override
  String toString() =>
      'UserEntity(userId: $userId, email: $email, displayName: $displayName, isActive: $isActive)';
}

/// Cashbook Entity - Buku kas
class CashbookEntity {
  final String cashbookId;
  final String userId;
  final String cashbookName;
  final String currency; // e.g., 'IDR'
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  CashbookEntity({
    required this.cashbookId,
    required this.userId,
    required this.cashbookName,
    this.currency = 'IDR',
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  @override
  String toString() =>
      'CashbookEntity(cashbookId: $cashbookId, cashbookName: $cashbookName, currency: $currency, isDefault: $isDefault)';
}

/// Wallet Entity - Dompet/Rekening
class WalletEntity {
  final String walletId;
  final String cashbookId;
  final WalletType type;
  final String walletName;
  final String? bankName;
  final String? accountNumber;
  final int initialBalance;
  final int currentBalance;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  WalletEntity({
    required this.walletId,
    required this.cashbookId,
    required this.type,
    required this.walletName,
    this.bankName,
    this.accountNumber,
    required this.initialBalance,
    required this.currentBalance,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  @override
  String toString() =>
      'WalletEntity(walletId: $walletId, walletName: $walletName, type: $type, currentBalance: $currentBalance)';
}

/// Category Entity - Kategori transaksi
class CategoryEntity {
  final String categoryId;
  final String? cashbookId; // null = kategori sistem default
  final TransactionType type;
  final String categoryName;
  final String icon; // Material Icons name
  final String color; // Hex color #RRGGBB
  final bool isSystem;
  final int sortOrder;

  CategoryEntity({
    required this.categoryId,
    this.cashbookId,
    required this.type,
    required this.categoryName,
    required this.icon,
    required this.color,
    this.isSystem = false,
    this.sortOrder = 0,
  });

  @override
  String toString() =>
      'CategoryEntity(categoryId: $categoryId, categoryName: $categoryName, type: $type, isSystem: $isSystem)';
}

/// Transaction Entity - Transaksi tunggal
class TransactionEntity {
  final String transactionId;
  final String cashbookId;
  final String walletId;
  final String? categoryId;
  final TransactionType type;
  final int amount; // Amount dalam Rupiah
  final String? name; // Keterangan transaksi
  final String? notes;
  final String? attachmentUrl;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  // Joined fields untuk display
  final String? walletName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  TransactionEntity({
    required this.transactionId,
    required this.cashbookId,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.name,
    this.notes,
    this.attachmentUrl,
    required this.transactionDate,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.walletName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  @override
  String toString() =>
      'TransactionEntity(transactionId: $transactionId, type: $type, amount: $amount, name: $name)';
}

/// Transfer Entity - Transfer antar dompet
class TransferEntity {
  final String transferId;
  final String cashbookId;
  final String fromWalletId;
  final String toWalletId;
  final int amount;
  final String? notes;
  final DateTime transferDate;
  final DateTime createdAt;

  // Joined fields untuk display
  final String? fromWalletName;
  final String? toWalletName;

  TransferEntity({
    required this.transferId,
    required this.cashbookId,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.notes,
    required this.transferDate,
    required this.createdAt,
    this.fromWalletName,
    this.toWalletName,
  });

  @override
  String toString() =>
      'TransferEntity(transferId: $transferId, from: $fromWalletName, to: $toWalletName, amount: $amount)';
}

/// Recurring Transaction Entity - Transaksi berulang
class RecurringTransactionEntity {
  final String recurringId;
  final String cashbookId;
  final String walletId;
  final String? categoryId;
  final TransactionType type;
  final int amount;
  final String name;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;

  RecurringTransactionEntity({
    required this.recurringId,
    required this.cashbookId,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.name,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  String toString() =>
      'RecurringTransactionEntity(recurringId: $recurringId, name: $name, frequency: $frequency)';
}
