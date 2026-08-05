import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money_amount.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool hasTransferWalletPair(List<WalletEntity> wallets) => wallets.length >= 2;

bool isTransferSourceSufficient(WalletEntity wallet, int amount) {
  return wallet.currentBalance >= amount;
}

List<WalletEntity> transferDestinationOptions(
  List<WalletEntity> wallets,
  String? sourceWalletId,
) {
  return wallets.where((wallet) => wallet.walletId != sourceWalletId).toList();
}

/// Typed state for the five-step income/expense add flow.
class TransactionDraft {
  final int amount;
  final String? categoryId;
  final String? walletId;
  final DateTime transactionDate;
  final String notes;

  const TransactionDraft({
    required this.amount,
    required this.transactionDate,
    this.categoryId,
    this.walletId,
    this.notes = '',
  });

  factory TransactionDraft.initial() {
    return TransactionDraft(
      amount: 0,
      transactionDate: dateOnly(DateTime.now()),
    );
  }

  bool get canSubmit =>
      Validators.validateAmountValue(amount) == null &&
      categoryId != null &&
      walletId != null &&
      Validators.validatePastDate(transactionDate) == null &&
      Validators.validateNotes(notes) == null;

  TransactionDraft copyWith({
    int? amount,
    Object? categoryId = _unset,
    Object? walletId = _unset,
    DateTime? transactionDate,
    String? notes,
  }) {
    return TransactionDraft(
      amount: amount ?? this.amount,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      walletId: identical(walletId, _unset)
          ? this.walletId
          : walletId as String?,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
    );
  }
}

/// Typed state for the five-step transfer add flow.
class TransferDraft {
  final int amount;
  final String? sourceWalletId;
  final String? destinationWalletId;
  final DateTime transferDate;
  final String notes;

  const TransferDraft({
    required this.amount,
    required this.transferDate,
    this.sourceWalletId,
    this.destinationWalletId,
    this.notes = '',
  });

  factory TransferDraft.initial() {
    return TransferDraft(amount: 0, transferDate: dateOnly(DateTime.now()));
  }

  bool get canSubmit =>
      Validators.validateAmountValue(amount) == null &&
      sourceWalletId != null &&
      destinationWalletId != null &&
      sourceWalletId != destinationWalletId &&
      Validators.validatePastDate(transferDate) == null &&
      Validators.validateNotes(notes) == null;

  TransferDraft copyWith({
    int? amount,
    Object? sourceWalletId = _unset,
    Object? destinationWalletId = _unset,
    DateTime? transferDate,
    String? notes,
  }) {
    return TransferDraft(
      amount: amount ?? this.amount,
      sourceWalletId: identical(sourceWalletId, _unset)
          ? this.sourceWalletId
          : sourceWalletId as String?,
      destinationWalletId: identical(destinationWalletId, _unset)
          ? this.destinationWalletId
          : destinationWalletId as String?,
      transferDate: transferDate ?? this.transferDate,
      notes: notes ?? this.notes,
    );
  }
}

const Object _unset = Object();

/// Small auto-disposed controller for transaction draft mutations.
class TransactionDraftController extends AutoDisposeNotifier<TransactionDraft> {
  @override
  TransactionDraft build() => TransactionDraft.initial();

  bool appendDigit(int digit) {
    final nextAmount = appendMoneyDigit(state.amount, digit);
    if (nextAmount == state.amount) return false;
    state = state.copyWith(amount: nextAmount);
    return true;
  }

  void deleteDigit() {
    state = state.copyWith(amount: removeMoneyDigit(state.amount));
  }

  void setAmount(int amount) {
    if (amount < 0 || amount > maxMoneyAmount) return;
    state = state.copyWith(amount: amount);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setWallet(String? walletId) {
    state = state.copyWith(walletId: walletId);
  }

  void setDate(DateTime value) {
    final normalized = dateOnly(value);
    if (normalized.isAfter(dateOnly(DateTime.now()))) return;
    state = state.copyWith(transactionDate: normalized);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }
}

/// Small auto-disposed controller for transfer draft mutations.
class TransferDraftController extends AutoDisposeNotifier<TransferDraft> {
  @override
  TransferDraft build() => TransferDraft.initial();

  bool appendDigit(int digit) {
    final nextAmount = appendMoneyDigit(state.amount, digit);
    if (nextAmount == state.amount) return false;
    state = state.copyWith(amount: nextAmount);
    return true;
  }

  void deleteDigit() {
    state = state.copyWith(amount: removeMoneyDigit(state.amount));
  }

  void setAmount(int amount) {
    if (amount < 0 || amount > maxMoneyAmount) return;
    state = state.copyWith(amount: amount);
  }

  void setSourceWallet(String? walletId) {
    final destination = walletId == state.destinationWalletId
        ? null
        : state.destinationWalletId;
    state = state.copyWith(
      sourceWalletId: walletId,
      destinationWalletId: destination,
    );
  }

  void setDestinationWallet(String? walletId) {
    if (walletId != null && walletId == state.sourceWalletId) return;
    state = state.copyWith(destinationWalletId: walletId);
  }

  void setDate(DateTime value) {
    final normalized = dateOnly(value);
    if (normalized.isAfter(dateOnly(DateTime.now()))) return;
    state = state.copyWith(transferDate: normalized);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }
}
