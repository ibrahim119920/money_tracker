import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/entities.dart';
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
  ProviderSubscription<AsyncValue<CashbookEntity?>>?
  _defaultCashbookSubscription;
  ProviderSubscription<AsyncValue<List<CashbookEntity>>>?
  _cashbooksSubscription;
  ProviderSubscription<AsyncValue<List<WalletEntity>>>? _walletsSubscription;

  @override
  void initState() {
    super.initState();
    _defaultCashbookSubscription = ref
        .listenManual<AsyncValue<CashbookEntity?>>(
          defaultCashbookProvider,
          (_, _) => _tryNavigate(),
        );
    _cashbooksSubscription = ref.listenManual<AsyncValue<List<CashbookEntity>>>(
      cashbooksProvider,
      (_, _) => _tryNavigate(),
    );
    _walletsSubscription = ref.listenManual<AsyncValue<List<WalletEntity>>>(
      walletsProvider,
      (_, _) => _tryNavigate(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _defaultCashbookSubscription?.close();
    _cashbooksSubscription?.close();
    _walletsSubscription?.close();
    super.dispose();
  }

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerBackground = isDark
        ? colorScheme.surfaceContainerLowest
        : AppColors.background;
    final accentLavender = isDark ? AppColors.darkLavender : AppColors.lavender;
    final accentLime = isDark ? AppColors.darkLime : AppColors.lime;
    final accentMint = isDark ? AppColors.darkMint : AppColors.mint;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final iconColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final progressColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    // Trigger provider loading
    ref.watch(defaultCashbookProvider);
    ref.watch(cashbooksProvider);
    ref.watch(walletsProvider);

    return Scaffold(
      backgroundColor: outerBackground,
      body: Stack(
        children: [
          Positioned(
            top: -72,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: accentLavender.withValues(alpha: isDark ? 0.18 : 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -56,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: accentLime.withValues(alpha: isDark ? 0.12 : 0.14),
                borderRadius: BorderRadius.circular(52),
              ),
            ),
          ),
          Positioned(
            bottom: 72,
            right: 24,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accentMint.withValues(alpha: isDark ? 0.20 : 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon / logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: iconColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Money Tracker',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola keuangan dengan mudah',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
