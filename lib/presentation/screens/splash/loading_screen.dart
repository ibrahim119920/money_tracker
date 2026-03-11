import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/providers.dart';

/// Loading screen yang muncul setelah auth berhasil, sebelum masuk Dashboard.
///
/// Pre-load urutan:
/// 1. [defaultCashbookProvider] → resolve → set [activeCashbookProvider]
/// 2. [cashbooksProvider] → resolve
/// 3. [walletsProvider] → re-run dengan active cashbook → resolve (data asli)
///
/// Navigasi ke Dashboard hanya terjadi ketika ketiganya sudah selesai,
/// sehingga [_TutorialOverlay] di Dashboard tidak pernah munculkan false positive.
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  bool _navigated = false;

  void _tryNavigate() {
    if (_navigated || !mounted) return;

    final defaultCashbook = ref.read(defaultCashbookProvider);
    final cashbooks = ref.read(cashbooksProvider);
    final wallets = ref.read(walletsProvider);

    // defaultCashbook dan cashbooks harus selesai.
    // walletsProvider tidak boleh sedang loading (sudah punya data real setelah
    // defaultCashbookProvider men-set activeCashbookProvider).
    final ready =
        defaultCashbook.hasValue && cashbooks.hasValue && !wallets.isLoading;

    if (ready) {
      _navigated = true;
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger provider loading
    ref.watch(defaultCashbookProvider);
    ref.watch(cashbooksProvider);
    ref.watch(walletsProvider);

    // Monitor perubahan state ketiga provider
    ref.listen(defaultCashbookProvider, (_, __) => _tryNavigate());
    ref.listen(cashbooksProvider, (_, __) => _tryNavigate());
    ref.listen(walletsProvider, (_, __) => _tryNavigate());

    // Cek langsung saat build (kalau data sudah ada di cache provider)
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon / logo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Money Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola keuangan dengan mudah',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
