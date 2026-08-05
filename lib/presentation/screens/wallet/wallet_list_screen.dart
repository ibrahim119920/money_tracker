import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

/// List screen untuk menampilkan semua dompet
class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Dompet')),
      body: SafeArea(
        top: false,
        child: walletsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Gagal memuat dompet: $error'),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(walletsProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
          data: (wallets) {
            if (wallets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Belum ada dompet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () =>
                          context.push('/wallets/form', extra: null),
                      child: const Text('Tambah Dompet Sekarang'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
              ),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                return WalletListItem(
                  wallet: wallet,
                  onEdit: () {
                    context.push('/wallets/form', extra: wallet);
                  },
                  onDelete: () {
                    _deleteWallet(context, ref, wallet);
                  },
                  onTap: () {
                    context.push('/wallets/detail', extra: wallet);
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/wallets/form', extra: null),
        icon: const Icon(Icons.add),
        label: const Text('Tambahkan Wallet'),
      ),
    );
  }

  Future<void> _deleteWallet(
    BuildContext context,
    WidgetRef ref,
    WalletEntity wallet,
  ) async {
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: const Text('Riwayat transaksi dompet ini tetap tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(walletRepositoryProvider);
      await repository.deactivateWallet(wallet.walletId);

      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dompet berhasil dihapus'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Individual wallet list item widget
class WalletListItem extends StatelessWidget {
  final WalletEntity wallet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const WalletListItem({
    super.key,
    required this.wallet,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  Color _getIconColor(ColorScheme colorScheme, WalletType type) {
    switch (type) {
      case WalletType.cash:
        return colorScheme.successColor;
      case WalletType.bankAcc:
        return colorScheme.primary;
      case WalletType.eWallet:
        return colorScheme.transferColor;
    }
  }

  IconData _getIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.payments;
      case WalletType.bankAcc:
        return Icons.account_balance;
      case WalletType.eWallet:
        return Icons.phone_android;
    }
  }

  String _getSubtitle() {
    if (wallet.bankName != null) {
      return wallet.bankName!;
    }

    switch (wallet.type) {
      case WalletType.cash:
        return 'Tunai';
      case WalletType.bankAcc:
        return 'Rekening Bank';
      case WalletType.eWallet:
        return 'Dompet Digital';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = _getIconColor(colorScheme, wallet.type);
    final balanceColor = wallet.currentBalance >= 0
        ? colorScheme.onSurface
        : colorScheme.expenseColor;

    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: AppRadius.smallBorder,
          ),
          child: Icon(_getIcon(wallet.type), color: iconColor),
        ),
        title: Text(
          wallet.walletName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          _getSubtitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      CurrencyFormatter.format(wallet.currentBalance),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20),
                        SizedBox(width: 12),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
