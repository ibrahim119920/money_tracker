import '../../domain/entities/entities.dart';

/// User Model - untuk JSON dari Supabase
class UserModel {
  final String userId;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  UserModel({
    required this.userId,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      userId: userId,
      email: email,
      displayName: displayName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  @override
  String toString() => 'UserModel(userId: $userId, email: $email)';
}

/// Cashbook Model
class CashbookModel {
  final String cashbookId;
  final String userId;
  final String cashbookName;
  final String currency;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  CashbookModel({
    required this.cashbookId,
    required this.userId,
    required this.cashbookName,
    this.currency = 'IDR',
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory CashbookModel.fromJson(Map<String, dynamic> json) {
    return CashbookModel(
      cashbookId: json['cashbook_id'] as String,
      userId: json['user_id'] as String,
      cashbookName: json['cashbook_name'] as String,
      currency: json['currency'] as String? ?? 'IDR',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashbook_id': cashbookId,
      'user_id': userId,
      'cashbook_name': cashbookName,
      'currency': currency,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  CashbookEntity toEntity() {
    return CashbookEntity(
      cashbookId: cashbookId,
      userId: userId,
      cashbookName: cashbookName,
      currency: currency,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }

  @override
  String toString() =>
      'CashbookModel(cashbookId: $cashbookId, name: $cashbookName)';
}

/// Wallet Model
class WalletModel {
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

  WalletModel({
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

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['wallet_id'] as String,
      cashbookId: json['cashbook_id'] as String,
      type: WalletType.fromString(json['type'] as String) ?? WalletType.cash,
      walletName: json['wallet_name'] as String,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      initialBalance: json['initial_balance'] as int,
      currentBalance: json['current_balance'] as int,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      'cashbook_id': cashbookId,
      'type': type.value,
      'wallet_name': walletName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WalletEntity toEntity() {
    return WalletEntity(
      walletId: walletId,
      cashbookId: cashbookId,
      type: type,
      walletName: walletName,
      bankName: bankName,
      accountNumber: accountNumber,
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'WalletModel(walletId: $walletId, name: $walletName)';
}

/// Category Model
class CategoryModel {
  final String categoryId;
  final String? cashbookId;
  final TransactionType type;
  final String categoryName;
  final String icon;
  final String color;
  final bool isSystem;
  final int sortOrder;

  CategoryModel({
    required this.categoryId,
    this.cashbookId,
    required this.type,
    required this.categoryName,
    required this.icon,
    required this.color,
    this.isSystem = false,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'] as String,
      cashbookId: json['cashbook_id'] as String?,
      type:
          TransactionType.fromString(json['type'] as String) ??
          TransactionType.expense,
      categoryName: json['category_name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isSystem: json['is_system'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'cashbook_id': cashbookId,
      'type': type.value,
      'category_name': categoryName,
      'icon': icon,
      'color': color,
      'is_system': isSystem,
      'sort_order': sortOrder,
    };
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      categoryId: categoryId,
      cashbookId: cashbookId,
      type: type,
      categoryName: categoryName,
      icon: icon,
      color: color,
      isSystem: isSystem,
      sortOrder: sortOrder,
    );
  }

  @override
  String toString() =>
      'CategoryModel(categoryId: $categoryId, name: $categoryName)';
}

/// Transaction Model
class TransactionModel {
  final String transactionId;
  final String cashbookId;
  final String walletId;
  final String? categoryId;
  final TransactionType type;
  final int amount;
  final String? name;
  final String? notes;
  final String? attachmentUrl;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final String? walletName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  TransactionModel({
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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transaction_id'] as String,
      cashbookId: json['cashbook_id'] as String,
      walletId: json['wallet_id'] as String,
      categoryId: json['category_id'] as String?,
      type:
          TransactionType.fromString(json['type'] as String) ??
          TransactionType.expense,
      amount: json['amount'] as int,
      name: json['name'] as String?,
      notes: json['notes'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      walletName: json['wallet_name'] as String?,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'cashbook_id': cashbookId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type.value,
      'amount': amount,
      'name': name,
      'notes': notes,
      'attachment_url': attachmentUrl,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      transactionId: transactionId,
      cashbookId: cashbookId,
      walletId: walletId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      name: name,
      notes: notes,
      attachmentUrl: attachmentUrl,
      transactionDate: transactionDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      walletName: walletName,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
    );
  }

  @override
  String toString() =>
      'TransactionModel(transactionId: $transactionId, amount: $amount)';
}

/// Transfer Model
class TransferModel {
  final String transferId;
  final String cashbookId;
  final String fromWalletId;
  final String toWalletId;
  final int amount;
  final String? notes;
  final DateTime transferDate;
  final DateTime createdAt;
  final String? fromWalletName;
  final String? toWalletName;

  TransferModel({
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

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      transferId: json['transfer_id'] as String,
      cashbookId: json['cashbook_id'] as String,
      fromWalletId: json['from_wallet_id'] as String,
      toWalletId: json['to_wallet_id'] as String,
      amount: json['amount'] as int,
      notes: json['notes'] as String?,
      transferDate: DateTime.parse(json['transfer_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      fromWalletName: json['from_wallet_name'] as String?,
      toWalletName: json['to_wallet_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transfer_id': transferId,
      'cashbook_id': cashbookId,
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'notes': notes,
      'transfer_date': transferDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransferEntity toEntity() {
    return TransferEntity(
      transferId: transferId,
      cashbookId: cashbookId,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      notes: notes,
      transferDate: transferDate,
      createdAt: createdAt,
      fromWalletName: fromWalletName,
      toWalletName: toWalletName,
    );
  }

  @override
  String toString() =>
      'TransferModel(transferId: $transferId, amount: $amount)';
}
