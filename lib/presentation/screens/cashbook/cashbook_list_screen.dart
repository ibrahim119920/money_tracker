import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

/// List screen untuk menampilkan semua buku kas
class CashbookListScreen extends ConsumerWidget {
  const CashbookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashbooksAsync = ref.watch(cashbooksProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Buku Kas')),
      body: SafeArea(
        top: false,
        child: cashbooksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Gagal memuat buku kas: $error'),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(cashbooksProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
          data: (cashbooks) {
            if (cashbooks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada buku kas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () =>
                          context.push('/cashbooks/form', extra: null),
                      child: const Text('Tambah Buku Kas Sekarang'),
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
              itemCount: cashbooks.length,
              itemBuilder: (context, index) {
                final cashbook = cashbooks[index];
                return CashbookListItem(
                  cashbook: cashbook,
                  onEdit: () {
                    context.push('/cashbooks/form', extra: cashbook);
                  },
                  onSetDefault: () {
                    _setDefaultCashbook(
                      context,
                      ref,
                      cashbook,
                      currentUser.value?.userId ?? '',
                    );
                  },
                  onDelete: () {
                    _deleteCashbook(context, ref, cashbook);
                  },
                  onTap: () {
                    ref.read(activeCashbookProvider.notifier).state = cashbook;
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cashbooks/form', extra: null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _setDefaultCashbook(
    BuildContext context,
    WidgetRef ref,
    CashbookEntity cashbook,
    String userId,
  ) async {
    try {
      final repository = ref.read(cashbookRepositoryProvider);
      await repository.setDefaultCashbook(
        userId: userId,
        cashbookId: cashbook.cashbookId,
      );

      ref.invalidate(cashbooksProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Buku kas utama berhasil diubah'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteCashbook(
    BuildContext context,
    WidgetRef ref,
    CashbookEntity cashbook,
  ) async {
    // Jika cashbook default, tampilkan error
    if (cashbook.isDefault) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Buku kas utama tidak dapat dihapus'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Tampilkan confirmation dialog
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku Kas?'),
        content: const Text('Semua data dalam buku kas ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(cashbookRepositoryProvider);
      await repository.deleteCashbook(cashbook.cashbookId);

      ref.invalidate(cashbooksProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Buku kas berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Individual cashbook list item widget
class CashbookListItem extends ConsumerWidget {
  final CashbookEntity cashbook;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CashbookListItem({
    super.key,
    required this.cashbook,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(
      FutureProvider<int>((ref) async {
        final repository = ref.watch(cashbookRepositoryProvider);
        return repository.getTotalBalance(cashbook.cashbookId);
      }),
    );

    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.book_outlined, color: colorScheme.primary),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cashbook.cashbookName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (cashbook.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: AppRadius.smallBorder,
                ),
                child: Text(
                  'Utama',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: balanceAsync.when(
          loading: () => const Text('Menghitung...'),
          error: (_, __) => const Text('Saldo -'),
          data: (balance) => Text(
            '${AppStrings.currentBalance} ${CurrencyFormatter.format(balance)}',
          ),
        ),
        trailing: PopupMenuButton<String>(
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
            if (!cashbook.isDefault)
              const PopupMenuItem(
                value: 'setDefault',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 12),
                    Text('Set sebagai Utama'),
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
              case 'setDefault':
                onSetDefault();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
        ),
      ),
    );
  }
}
