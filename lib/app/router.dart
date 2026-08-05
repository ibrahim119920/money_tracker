import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/entities.dart';
import '../presentation/providers/providers.dart';
import '../presentation/screens/auth/landing_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/cashbook/cashbook_form_screen.dart';
import '../presentation/screens/cashbook/cashbook_list_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/wallet/wallet_detail_screen.dart';
import '../presentation/screens/wallet/wallet_form_screen.dart';
import '../presentation/screens/wallet/wallet_list_screen.dart';
import '../presentation/screens/transaction/transaction_form_screen.dart';
import '../presentation/screens/transaction/transaction_detail_screen.dart';
import '../presentation/screens/transaction/transaction_list_screen.dart';
import '../presentation/screens/transfer/transfer_screen.dart';
import '../presentation/screens/report/monthly_report_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/splash/loading_screen.dart';

/// Route names constant
class AppRoutes {
  static const String splash = '/splash';
  static const String loading = '/loading';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String cashbooks = '/cashbooks';
  static const String wallets = '/wallets';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String transfer = '/transfer';
  static const String monthlyReport = '/report/monthly';
  static const String annualReport = '/report/annual';
  static const String settings = '/settings';
}

/// Notifier yang memantau perubahan auth state untuk merefresh GoRouter
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}

/// GoRouter provider
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      // Auth masih loading → tampilkan splash dulu
      if (authAsync.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isLoggedIn = authAsync.valueOrNull?.session != null;

      // Dari splash → arahkan ke tujuan yang benar
      if (loc == AppRoutes.splash) {
        return isLoggedIn ? AppRoutes.loading : AppRoutes.landing;
      }

      // Halaman loading hanya untuk user yang login
      if (loc == AppRoutes.loading && !isLoggedIn) {
        return AppRoutes.landing;
      }

      // Sudah login → paksa ke loading dari halaman publik
      if (isLoggedIn &&
          (loc == AppRoutes.landing ||
              loc == AppRoutes.login ||
              loc == AppRoutes.register)) {
        return AppRoutes.loading;
      }

      // Belum login, akses halaman yang butuh auth → ke landing. Semua route
      // data sekarang dilindungi, bukan hanya dashboard.
      final isProtectedRoute =
          loc == AppRoutes.dashboard ||
          loc.startsWith('/cashbooks') ||
          loc.startsWith('/wallets') ||
          loc.startsWith('/transactions') ||
          loc.startsWith('/transfer') ||
          loc.startsWith('/report') ||
          loc.startsWith('/settings');
      if (!isLoggedIn && isProtectedRoute) {
        return AppRoutes.landing;
      }

      return null;
    },
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash Route (sementara saat auth loading)
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),

      // Loading Route (pre-warm data sebelum masuk Dashboard)
      GoRoute(
        path: AppRoutes.loading,
        builder: (_, __) => const LoadingScreen(),
      ),

      // Landing Route
      GoRoute(path: '/landing', builder: (_, __) => const LandingScreen()),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main Routes
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Cashbook Routes
      GoRoute(
        path: AppRoutes.cashbooks,
        name: 'cashbooks',
        builder: (context, state) => const CashbookListScreen(),
      ),
      GoRoute(
        path: '/cashbooks/form',
        name: 'cashbookForm',
        builder: (context, state) =>
            CashbookFormScreen(cashbook: state.extra as CashbookEntity?),
      ),

      // Wallet Routes
      GoRoute(
        path: AppRoutes.wallets,
        name: 'wallets',
        builder: (context, state) => const WalletListScreen(),
      ),
      GoRoute(
        path: '/wallets/form',
        name: 'walletForm',
        builder: (context, state) =>
            WalletFormScreen(wallet: state.extra as WalletEntity?),
      ),
      GoRoute(
        path: '/wallets/detail',
        name: 'walletDetail',
        builder: (context, state) =>
            WalletDetailScreen(wallet: state.extra as WalletEntity),
      ),

      // Transaction Routes
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/transactions/form',
        name: 'transactionForm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TransactionFormScreen(
            type: extra['type'] as TransactionType,
            transaction: extra['transaction'] as TransactionEntity?,
          );
        },
      ),
      GoRoute(
        path: '/transactions/detail',
        name: 'transactionDetail',
        builder: (context, state) => TransactionDetailScreen(
          transaction: state.extra as TransactionEntity,
        ),
      ),
      GoRoute(
        path: AppRoutes.transfer,
        name: 'transfer',
        builder: (context, state) => const TransferScreen(),
      ),
      // Report Routes
      GoRoute(
        path: AppRoutes.monthlyReport,
        name: 'monthlyReport',
        builder: (context, state) => const MonthlyReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.fullPath}')),
    ),
  );
});

/// Layar loading sementara saat auth state sedang diinisialisasi
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
