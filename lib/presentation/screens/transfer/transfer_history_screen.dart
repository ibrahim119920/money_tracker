import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/providers.dart';

/// Transfer history remains separately discoverable at `/transfer/history`.
class TransferHistoryScreen extends ConsumerWidget {
  const TransferHistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(transfersProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(totalBalanceProvider);
    await ref
        .read(transfersProvider.future)
        .catchError((_) => <TransferEntity>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transfersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transfer'),
        backgroundColor: colorScheme.transferContainer,
        foregroundColor: colorScheme.onTransferColor,
        actions: [
          IconButton(
            tooltip: 'Tambah transfer',
            onPressed: () => context.push(AppRoutes.transfer),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: transfersAsync.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 180),
                Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (_, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                const SizedBox(height: AppSpacing.xxl),
                _HistoryState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Riwayat belum tersedia',
                  message: 'Periksa koneksi lalu coba lagi.',
                ),
                Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(transfersProvider),
                    child: const Text('Coba lagi'),
                  ),
                ),
              ],
            ),
            data: (transfers) {
              if (transfers.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  children: const [
                    SizedBox(height: AppSpacing.xxl),
                    _HistoryState(
                      icon: Icons.swap_horiz_outlined,
                      title: 'Belum ada transfer',
                      message:
                          'Transfer antar dompet yang berhasil akan muncul di sini.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                ),
                itemCount: transfers.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return _TransferHistoryCard(transfer: transfers[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HistoryState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
        ],
      ),
    );
  }
}

class _TransferHistoryCard extends StatelessWidget {
  final TransferEntity transfer;

  const _TransferHistoryCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final route =
        '${transfer.fromWalletName ?? 'Dompet asal'} → '
        '${transfer.toWalletName ?? 'Dompet tujuan'}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.transferContainer,
              borderRadius: AppRadius.smallBorder,
            ),
            child: Icon(Icons.swap_horiz, color: colorScheme.transferColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DateFormatter.formatLongDate(transfer.transferDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if ((transfer.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    transfer.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                CurrencyFormatter.format(transfer.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.transferColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
