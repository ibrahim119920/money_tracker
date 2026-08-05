import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-bound semantic colors for financial meaning and status feedback.
///
/// These colors are deliberately separate from the brand ColorScheme roles so
/// income, expense, and status feedback cannot accidentally inherit primary.
@immutable
class MoneyTrackerSemanticColors
    extends ThemeExtension<MoneyTrackerSemanticColors> {
  const MoneyTrackerSemanticColors({
    required this.income,
    required this.incomeContainer,
    required this.onIncomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.onExpenseContainer,
    required this.transfer,
    required this.transferContainer,
    required this.onTransferContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.neutralInfo,
    required this.neutralInfoContainer,
    required this.onNeutralInfoContainer,
  });

  final Color income;
  final Color incomeContainer;
  final Color onIncomeContainer;

  final Color expense;
  final Color expenseContainer;
  final Color onExpenseContainer;

  final Color transfer;
  final Color transferContainer;
  final Color onTransferContainer;

  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color neutralInfo;
  final Color neutralInfoContainer;
  final Color onNeutralInfoContainer;

  static const MoneyTrackerSemanticColors light = MoneyTrackerSemanticColors(
    income: AppColors.income,
    incomeContainer: AppColors.incomeContainer,
    onIncomeContainer: AppColors.onIncomeContainer,
    expense: AppColors.expense,
    expenseContainer: AppColors.expenseContainer,
    onExpenseContainer: AppColors.onExpenseContainer,
    transfer: AppColors.transfer,
    transferContainer: AppColors.transferContainer,
    onTransferContainer: AppColors.onTransferContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    neutralInfo: AppColors.neutralInfo,
    neutralInfoContainer: AppColors.neutralInfoContainer,
    onNeutralInfoContainer: AppColors.onNeutralInfoContainer,
  );

  static const MoneyTrackerSemanticColors dark = MoneyTrackerSemanticColors(
    income: AppColors.darkIncome,
    incomeContainer: AppColors.darkIncomeContainer,
    onIncomeContainer: AppColors.darkOnIncomeContainer,
    expense: AppColors.darkExpense,
    expenseContainer: AppColors.darkExpenseContainer,
    onExpenseContainer: AppColors.darkOnExpenseContainer,
    transfer: AppColors.darkTransfer,
    transferContainer: AppColors.darkTransferContainer,
    onTransferContainer: AppColors.darkOnTransferContainer,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    onWarningContainer: AppColors.darkOnWarningContainer,
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkSuccessContainer,
    onSuccessContainer: AppColors.darkOnSuccessContainer,
    neutralInfo: AppColors.darkNeutralInfo,
    neutralInfoContainer: AppColors.darkNeutralInfoContainer,
    onNeutralInfoContainer: AppColors.darkOnNeutralInfoContainer,
  );

  @override
  MoneyTrackerSemanticColors copyWith({
    Color? income,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? onExpenseContainer,
    Color? transfer,
    Color? transferContainer,
    Color? onTransferContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? neutralInfo,
    Color? neutralInfoContainer,
    Color? onNeutralInfoContainer,
  }) {
    return MoneyTrackerSemanticColors(
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      onExpenseContainer: onExpenseContainer ?? this.onExpenseContainer,
      transfer: transfer ?? this.transfer,
      transferContainer: transferContainer ?? this.transferContainer,
      onTransferContainer: onTransferContainer ?? this.onTransferContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      neutralInfo: neutralInfo ?? this.neutralInfo,
      neutralInfoContainer: neutralInfoContainer ?? this.neutralInfoContainer,
      onNeutralInfoContainer:
          onNeutralInfoContainer ?? this.onNeutralInfoContainer,
    );
  }

  @override
  MoneyTrackerSemanticColors lerp(
    covariant MoneyTrackerSemanticColors? other,
    double t,
  ) {
    if (other == null) return this;

    return MoneyTrackerSemanticColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      onIncomeContainer: Color.lerp(
        onIncomeContainer,
        other.onIncomeContainer,
        t,
      )!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer: Color.lerp(
        expenseContainer,
        other.expenseContainer,
        t,
      )!,
      onExpenseContainer: Color.lerp(
        onExpenseContainer,
        other.onExpenseContainer,
        t,
      )!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      transferContainer: Color.lerp(
        transferContainer,
        other.transferContainer,
        t,
      )!,
      onTransferContainer: Color.lerp(
        onTransferContainer,
        other.onTransferContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      neutralInfo: Color.lerp(neutralInfo, other.neutralInfo, t)!,
      neutralInfoContainer: Color.lerp(
        neutralInfoContainer,
        other.neutralInfoContainer,
        t,
      )!,
      onNeutralInfoContainer: Color.lerp(
        onNeutralInfoContainer,
        other.onNeutralInfoContainer,
        t,
      )!,
    );
  }
}

/// Convenient access to the semantic colors installed by [AppTheme].
extension MoneyTrackerSemanticColorsContext on BuildContext {
  MoneyTrackerSemanticColors get semanticColors {
    final theme = Theme.of(this);
    return theme.extension<MoneyTrackerSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? MoneyTrackerSemanticColors.dark
            : MoneyTrackerSemanticColors.light);
  }
}
