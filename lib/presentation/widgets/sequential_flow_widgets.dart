import 'package:flutter/material.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../domain/entities/entities.dart';
import '../icons/app_icons.dart';

/// Shared progress header for the sequential add flows.
class SequentialFlowProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;

  const SequentialFlowProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (currentStep + 1) / totalSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${currentStep + 1}/$totalSteps',
                semanticsLabel: 'Langkah ${currentStep + 1} dari $totalSteps',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared bottom navigation for a controlled sequential PageView.
class SequentialFlowNavigation extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool isLoading;

  const SequentialFlowNavigation({
    super.key,
    required this.onBack,
    required this.onContinue,
    required this.continueLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      elevation: AppElevation.low,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.xs,
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: AppIconSize.small),
                label: const Text('Kembali'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, AppComponentHeight.interactive),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : onContinue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppComponentHeight.interactive,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(continueLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent intro and scroll rhythm for category and wallet selection.
class SelectionStepShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const SelectionStepShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

/// Loading/error/empty panel shared by selection steps.
class SelectionStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SelectionStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: AppIconSize.hero,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Numpad that edits an integer amount and never requests the system keyboard.
class AmountKeypad extends StatelessWidget {
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final bool canDelete;

  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ]) ...[
          Row(
            children: [
              for (final digit in row)
                Expanded(
                  child: _AmountKeyButton(
                    key: ValueKey('amount-key-$digit'),
                    label: '$digit',
                    semanticLabel: 'Angka $digit',
                    onPressed: () => onDigit(digit),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Row(
          children: [
            Expanded(
              child: _AmountKeyButton(
                key: const ValueKey('amount-key-backspace'),
                icon: Icons.backspace_outlined,
                label: 'Hapus digit',
                semanticLabel: 'Hapus digit terakhir',
                onPressed: canDelete ? onBackspace : null,
              ),
            ),
            Expanded(
              child: _AmountKeyButton(
                key: const ValueKey('amount-key-0'),
                label: '0',
                semanticLabel: 'Angka 0',
                onPressed: () => onDigit(0),
              ),
            ),
            const Expanded(child: SizedBox(height: AppComponentHeight.field)),
          ],
        ),
      ],
    );
  }
}

class _AmountKeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  const _AmountKeyButton({
    super.key,
    this.label,
    this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: onPressed == null
              ? colorScheme.surfaceContainerLow
              : colorScheme.surfaceContainer,
          borderRadius: AppRadius.controlBorder,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.controlBorder,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: AppComponentHeight.field,
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: colorScheme.onSurface)
                    : Text(
                        label!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact, category-specific option tile used by the transaction flow.
class CategoryOptionTile extends StatelessWidget {
  final CategoryEntity category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryOptionTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = AppColors.chartColorFor(
      category.categoryId,
      colorScheme.brightness,
    );
    final background = selected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${category.categoryName}${selected ? ', dipilih' : ''}',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.controlBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 104),
            child: Ink(
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadius.controlBorder,
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: selected
                      ? AppBorder.focusWidth
                      : AppBorder.subtleWidth,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.forCategory(category.icon),
                          size: AppIconSize.object,
                          color: selected ? foreground : accent,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          category.categoryName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Icon(
                        AppIcons.selected,
                        size: AppIconSize.small,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wallet-specific option card showing identity, type, balance, and reason
/// when the card cannot be selected.
class WalletOptionCard extends StatelessWidget {
  final WalletEntity wallet;
  final bool selected;
  final String? disabledReason;
  final VoidCallback? onTap;

  const WalletOptionCard({
    super.key,
    required this.wallet,
    required this.selected,
    required this.disabledReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    final background = selected
        ? colorScheme.primaryContainer
        : disabled
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerLow;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final semanticLabel = [
      wallet.walletName,
      wallet.type.label,
      'Saldo ${CurrencyFormatter.format(wallet.currentBalance)}',
      if (disabledReason != null) disabledReason ?? '',
      if (selected) 'dipilih',
    ].join(', ');

    return Semantics(
      container: true,
      button: true,
      enabled: !disabled,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 140),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: selected
                      ? AppBorder.focusWidth
                      : AppBorder.subtleWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.forWalletType(wallet.type),
                        color: disabled
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                        size: AppIconSize.object,
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(
                          AppIcons.selected,
                          size: AppIconSize.regular,
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    wallet.walletName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    wallet.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.format(wallet.currentBalance),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (disabledReason != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      disabledReason!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
