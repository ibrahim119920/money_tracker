# Money Tracker — Project Dictionary
> Panduan referensi cepat untuk Copilot. **Terakhir diperbarui: August 8, 2026 (Sprint 4.31.1 - Projection & Category Accuracy Fixes)**

> **📖 Dokumentasi Lengkap**: Lihat `AGENTS.md` (entry point) dan folder `docs/` untuk dokumentasi arsitektur yang lebih detail dan AI-friendly.

---

## FILE MAP — Core

| File | Class / Konten |
|---|---|
| `lib/main.dart` | `MoneyTrackerApp`, `_AppInitErrorWidget`, init: `await initializeDateFormatting('id_ID', null)` ⚠️ diperlukan sebelum `runApp()` |
| `lib/app/router.dart` | `AppRoutes` (konstanta path), `goRouterProvider`, `_RouterNotifier`, `_SplashScreen` |
| `lib/app/localization.dart` | `appLocalizationsDelegates`, `appSupportedLocales`, `appDefaultLocale` untuk konfigurasi locale Material/Widgets Bahasa Indonesia |
| `lib/app/theme.dart` | `AppTheme.getLightTheme()`, `AppTheme.getDarkTheme()` (Material 3 `ColorScheme`, component themes, typography, surface hierarchy, dan system bars) |
| `lib/core/constants/app_colors.dart` | `AppColors` (palette warm-neutral, semantic compatibility, deterministic wallet/chart palettes, dan extension `MoneyTrackerColorScheme`) |
| `lib/core/constants/app_auth_config.dart` | `AppAuthConfig.googleRedirectUri` untuk callback OAuth Android |
| `lib/core/constants/app_design_tokens.dart` | `AppSpacing`, restrained `AppRadius` scale, `AppBorder`, `AppElevation`, `AppIconSize`, `AppComponentHeight`, `AppMotion` |
| `lib/core/constants/app_semantic_colors.dart` | `MoneyTrackerSemanticColors` `ThemeExtension` untuk pasangan semantic light/dark |
| `lib/core/constants/app_strings.dart` | `AppStrings` — semua string UI Bahasa Indonesia |
| `lib/core/constants/supabase_keys.dart` | `SupabaseKeys.supabaseUrl`, `SupabaseKeys.supabaseAnonKey` |
| `lib/core/utils/currency_formatter.dart` | `CurrencyFormatter.format()`, `.parse()`, `.formatCompact()` |
| `lib/core/utils/date_formatter.dart` | `DateFormatter.formatLongDate()`, `.formatShortDate()`, `.formatMonthYear()`, `.relative()`, `.isFutureDate()` (local calendar day) |
| `lib/core/utils/money_amount.dart` | Integer Rupiah keypad helpers, leading-zero normalization, and BIGINT overflow guard |
| `lib/core/utils/validators.dart` | `Validators.validateEmail/Password/Amount/Name/Required/Notes/...` |

---

## FILE MAP — Data Layer

| File | Class / Konten |
|---|---|
| `lib/data/models/models.dart` | Barrel: `UserModel`, `CashbookModel`, `WalletModel`, `CategoryModel`, `TransactionModel`, `TransferModel` |
| `lib/data/repositories/cashbook_wallet_repository.dart` | `CashbookRepository`, `WalletRepository`, `TransactionRepository` (database category CRUD, scoped transfers, future projection), `SettingsRepository` |

**Setiap model** punya: `fromJson()`, `toJson()`, `toEntity()`

---

## FILE MAP — Domain Layer

| File | Class / Konten |
|---|---|
| `lib/domain/entities/entities.dart` | `UserEntity`, `CashbookEntity`, `WalletEntity`, `CategoryEntity`, `TransactionEntity`, `TransferEntity`, `RecurringTransactionEntity`, `FutureTransactionImpact`, `FutureTransactionProjection` |
| `lib/domain/entities/entities.dart` | Enum: `WalletType` (cash/bankAcc/eWallet), `TransactionType` (income/expense), `RecurringFrequency` |
| `lib/domain/usecases/` | **KOSONG** — belum diimplementasi |

---

## FILE MAP — Presentation Layer

### Icon Foundation (Phase 2)
| File | Class / Konten |
|---|---|
| lib/presentation/icons/app_icons.dart | AppIcons — matching outlined/rounded navigation pairs, Dashboard actions, transaction and WalletType mappings, expanded normalized category aliases, and deterministic fallbacks; stored keys remain unchanged |
| test/app_icons_test.dart | Focused mapping, fallback, normalization, determinism, and 18/24/26/30/36 dp token coverage |
| test/dashboard_icon_system_test.dart | Dashboard light/dark golden, responsive widths 360/393/412, text scale 1.0/1.3, semantics, and direct transaction-action coverage |
| test/transaction_filter_segmented_control_test.dart | 360 dp equal-width type-filter measurement, overflow safety, selected semantics/colors, and provider-state interaction coverage |

### Providers
| File | Provider | Type | Catatan |
|---|---|---|---|
| `lib/presentation/providers/providers.dart` | `supabaseClientProvider` | `Provider` | DI untuk Supabase client |
| `lib/presentation/providers/providers.dart` | `sharedPreferencesProvider` | `Provider<Future<SharedPreferences>>` | Future instance SharedPreferences untuk persist `appThemeModeProvider` |
| `lib/presentation/providers/providers.dart` | `cashbookRepositoryProvider`, `walletRepositoryProvider`, `transactionRepositoryProvider`, `settingsRepositoryProvider` | `Provider` | DI untuk semua repository |
| `lib/presentation/providers/providers.dart` | `authStateProvider` | `StreamProvider` | Listen auth state changes |
| `lib/presentation/providers/providers.dart` | `currentUserProvider` | `FutureProvider` | Current logged-in user |
| `lib/presentation/providers/providers.dart` | `setupInProgressProvider` | `StateProvider<bool>` | ⚡ Flag untuk suppress router redirect saat onboarding |
| `lib/presentation/providers/providers.dart` | `activeCashbookProvider` | `StateProvider` | Cashbook yg sdg dipilih (set otomatis oleh defaultCashbookProvider) |
| `lib/presentation/providers/providers.dart` | `appThemeModeProvider` | `StateNotifierProvider<ThemeModeNotifier, ThemeMode>` | Theme mode runtime: sistem/terang/gelap + persist ke SharedPreferences |
| `lib/presentation/providers/providers.dart` | `cashbooksProvider` | `FutureProvider` | Daftar semua cashbook user; delegate ke `CashbookRepository.getUserCashbooks()` |
| `lib/presentation/providers/providers.dart` | `defaultCashbookProvider` | `FutureProvider` | ⚡ Auto-load default cashbook & set ke active |
| `lib/presentation/providers/providers.dart` | `walletsProvider` | `FutureProvider` | Dompet di active cashbook; delegate ke `WalletRepository.getWallets()` |
| `lib/presentation/providers/providers.dart` | `totalBalanceProvider` | `FutureProvider` | Total saldo semua dompet; delegate ke `CashbookRepository.getTotalBalance()` |
| `lib/presentation/providers/providers.dart` | `cashbookBalanceProvider` | `FutureProvider.family<int, String>` | Saldo per cashbook untuk row list yang stabil saat rebuild |
| `lib/presentation/providers/providers.dart` | `futureTransactionProjectionProvider` | `FutureProvider<FutureTransactionProjection>` | Saldo hari ini dan proyeksi akhir bulan, setelah future income/expense dikeluarkan dari trigger total |
| `lib/presentation/providers/providers.dart` | `categoriesProvider` | `FutureProvider.family` | By cashbookId |
| `lib/presentation/providers/providers.dart` | `transactionFilterProvider` | `StateProvider` | Filter (tipe, bulan) |
| `lib/presentation/providers/providers.dart` | `transactionHistorySegmentProvider` | `StateProvider<TransactionHistorySegment>` | Segmen All / Income / Expense / Transfer |
| `lib/presentation/providers/providers.dart` | `transactionsProvider` | `StreamProvider<List<TransactionEntity>>` | Transaksi dengan filter |
| `lib/presentation/providers/providers.dart` | `transactionListItemsProvider` | `Provider<AsyncValue<List<TransactionListItem>>>` | Daftar transaksi yang sudah dikelompokkan per tanggal untuk UI; grouping tidak dilakukan di build widget |
| `lib/presentation/providers/providers.dart` | `transactionDetailProvider` | `FutureProvider.family<TransactionEntity, String>` | Detail transaksi by `transactionId` + join wallet/category |
| `lib/presentation/providers/providers.dart` | `selectedMonthProvider` | `StateProvider<DateTime>` | Bulan yg dipilih di transaction list |
| `lib/presentation/providers/providers.dart` | `monthlySummaryProvider` | `FutureProvider` | Summary income/expense setiap bulan; delegate ke `TransactionRepository.getMonthlySummaryForReport()` |
| `lib/presentation/providers/providers.dart` | `transfersProvider` | `FutureProvider` | Transfer history; delegate ke `TransactionRepository.getTransfersByCashbook()` |
| `lib/presentation/providers/providers.dart` | `selectedMonthTransfersProvider` | `FutureProvider<List<TransferEntity>>` | Transfer cashbook aktif yang dibatasi bulan riwayat terpilih |
| `lib/presentation/providers/providers.dart` | `transactionDraftProvider` | `AutoDisposeNotifierProvider` | Typed sequential income/expense draft; integer amount and five-step fields |
| `lib/presentation/providers/providers.dart` | `transferDraftProvider` | `AutoDisposeNotifierProvider` | Typed sequential transfer draft; clears conflicting destination |
| `lib/presentation/providers/providers.dart` | `reportMonthProvider` | `StateProvider<DateTime>` | Bulan dipilih di halaman laporan |
| `lib/presentation/providers/providers.dart` | `reportMonthlySummaryProvider` | `FutureProvider.family<Map<String,int>, DateTime>` | Summary income/expense untuk bulan tertentu (laporan) |
| `lib/presentation/providers/providers.dart` | `reportCategoryBreakdownProvider` | `FutureProvider.family` | Pie chart data: breakdown per kategori. Param: `({cashbookId, month, transactionType})` |
| `lib/presentation/providers/providers.dart` | `reportYearlyTrendProvider` | `FutureProvider.family` | Bar chart data: trend 12 bulan. Param: `({cashbookId, year})` |

### Screens
| File | Class Utama | Status |
|---|---|---|
| `lib/presentation/screens/auth/landing_screen.dart` | `LandingScreen`, `_FeatureItem` | ✅ Lengkap — fade + slide animation, CTA ke login/register |
| `lib/presentation/screens/auth/login_screen.dart` | `LoginScreen`, `_FieldLabel` | ✅ Lengkap — email/password, Google Sign In placeholder, explicit redirect |
| `lib/presentation/screens/auth/register_screen.dart` | `RegisterScreen`, `_FieldLabel`, `_StepIndicator`, `_StepItem` | ✅ Lengkap — 4 fields, step indicator, terms checkbox, **auto-create cashbook default saat register** |
| `lib/presentation/screens/cashbook/cashbook_list_screen.dart` | `CashbookListScreen`, `CashbookListItem` | ✅ |
| `lib/presentation/screens/cashbook/cashbook_form_screen.dart` | `CashbookFormScreen` | ✅ |
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | `DashboardScreen`, `_DashboardScaffold`, `_DashboardBottomNav`, `_CashbookSwitcher`, `_TotalBalanceCard`, `_FutureBalanceProjection`, `_MonthlySection`, `_DashboardMonthNavigation`, `_WalletSection`, `_TutorialOverlay`, `_TutorialCard`, `_StepDot` | ✅ — persistent four-tab shell, scheduled balance projection, accessible vertical wallet cards, and shared month state |
| `lib/presentation/screens/splash/loading_screen.dart` | `LoadingScreen` — pre-warm providers sebelum masuk Dashboard | ✅ — readiness check moved out of build |
| `lib/presentation/screens/wallet/wallet_list_screen.dart` | `WalletListScreen`, `WalletListItem` | ✅ |
| `lib/presentation/screens/wallet/wallet_form_screen.dart` | `WalletFormScreen` | ✅ |
| `lib/presentation/screens/wallet/wallet_detail_screen.dart` | `WalletDetailScreen`, `_walletMonthlySummaryProvider`, `_walletTransactionsProvider` | ✅ — loading summary/transactions use lightweight placeholders |
| `lib/presentation/screens/transaction/transaction_list_screen.dart` | `TransactionListScreen`, `_FilterBar`, `_TypeFilterSegmentedControl`, `_TransferHistorySummary`, `_TransferHistoryTile`, `_MonthNavigation`, `_SummaryBar`, `_DateHeader`, `_MonthPickerDialog` | ✅ — flat grouped rows, four equal history segments, and month-scoped transfer rows |
| `lib/presentation/screens/transaction/transaction_add_flow_screen.dart` | `TransactionAddFlowScreen` | ✅ — sequential income/expense add with scheduled dates and shared category creation |
| `lib/presentation/screens/transaction/transaction_form_screen.dart` | `TransactionFormScreen`, `_AmountField` | ✅ — existing edit form remains at `/transactions/form`; uses shared category picker and scheduled dates |
| `lib/presentation/screens/transaction/transaction_detail_screen.dart` | `TransactionDetailScreen`, `_DetailRow` | ✅ — uses the shared `FutureTransactionBadge` from `transaction_tile.dart` for scheduled income/expense |
| `lib/presentation/screens/transfer/transfer_screen.dart` | `TransferScreen` | ✅ — sequential five-step transfer add flow |
| `lib/presentation/screens/transfer/transfer_history_screen.dart` | `TransferHistoryScreen` | ✅ — dedicated `/transfer/history` history screen |
| `lib/presentation/screens/report/monthly_report_screen.dart` | `MonthlyReportScreen`, `_MonthPicker`, `_MonthYearPickerDialog`, `_SummarySection`, `_ReportSummarySurface`, `_PieChartSection`, `_ReportTypeSegmentedControl`, `_CategoryLegend`, `_BarChartSection`, `_LegendDot` | ✅ — tonal grouped surfaces, compact navigation, semantic chart controls; supports standalone route and embedded dashboard tab |
| `lib/presentation/screens/settings/settings_screen.dart` | `SettingsScreen` | ✅ P0 — profile, password, theme mode, default cashbook, about, logout; supports standalone route and embedded dashboard tab |

### Widgets
| File | Class | Catatan |
|---|---|---|
| `lib/presentation/widgets/transaction_tile.dart` | `TransactionTile`, `FutureTransactionBadge` (props: transaction, onTap, showWalletName, showDivider, dense) | Flat Android list row with centralized category icon mapping, an accessible scheduled badge, semantic colors, divider option, and safe amount overflow |
| `lib/presentation/widgets/app_section_header.dart` | `AppSectionHeader` | Header section ringkas dengan action opsional atau trailing widget; tanpa business logic |
| `lib/presentation/widgets/money_metric.dart` | `MoneyMetric`, `MoneyMetricType` | Metric uang dengan nilai yang sudah diformat, semantic color, layout compact/regular, dan overflow aman |
| `lib/presentation/widgets/sequential_flow_widgets.dart` | `SequentialFlowProgress`, `SequentialFlowNavigation`, `AmountKeypad`, `CategoryOptionTile`, `CategoryPickerSheet`, `WalletOptionCard`, selection state shell | Shared sequential shell with responsive category picker, persisted category creation, purpose-specific selection cards, and TalkBack semantics |

### Sequential Draft State
| File | Class | Catatan |
|---|---|---|
| `lib/presentation/state/sequential_add_state.dart` | `TransactionDraft`, `TransactionDraftController` | Typed auto-disposed draft; no UI/controller/backend ownership |
| `lib/presentation/state/sequential_add_state.dart` | `TransferDraft`, `TransferDraftController` | Source/destination exclusion, balance eligibility, date/notes validation |

---

## ROUTE TABLE

| Konstanta `AppRoutes` | Path | Screen | Catatan |
|---|---|---|---|
| `AppRoutes.splash` | `/splash` | `_SplashScreen` | Loading spinner, inisialisasi auth |
| `AppRoutes.landing` | `/landing` | `LandingScreen` | Entry publik (belum login), fade+slide anim |
| `AppRoutes.login` | `/login` | `LoginScreen` | Back button → `/landing` |
| `AppRoutes.register` | `/register` | `RegisterScreen` | Back button → `/landing` |
| `AppRoutes.dashboard` | `/dashboard` | `DashboardScreen` | Protected route; owns in-place Dashboard/Transaksi/Laporan/Pengaturan tab shell |
| `AppRoutes.cashbooks` | `/cashbooks` | `CashbookListScreen` | |
| `AppRoutes.cashbookForm` | `/cashbooks/form` | `CashbookFormScreen` | |
| `AppRoutes.wallets` | `/wallets` | `WalletListScreen` | |
| `AppRoutes.walletForm` | `/wallets/form` | `WalletFormScreen` | |
| `AppRoutes.walletDetail` | `/wallets/detail` | `WalletDetailScreen` | |
| `AppRoutes.transactions` | `/transactions` | `TransactionListScreen` | |
| `AppRoutes.addTransaction` | `/transactions/add` | Redirect to income add flow | Legacy compatibility path |
| `AppRoutes.addIncomeTransaction` | `/transactions/add/income` | `TransactionAddFlowScreen(income)` | Sequential add |
| `AppRoutes.addExpenseTransaction` | `/transactions/add/expense` | `TransactionAddFlowScreen(expense)` | Sequential add |
| `AppRoutes.transactionForm` | `/transactions/form` | `TransactionFormScreen` | Existing edit form; invalid extras use safe fallback |
| `AppRoutes.transactionDetail` | `/transactions/detail` | `TransactionDetailScreen` | |
| `AppRoutes.transfer` | `/transfer` | `TransferScreen` | Sequential transfer add |
| `AppRoutes.transferHistory` | `/transfer/history` | `TransferHistoryScreen` | Transfer history |
| `AppRoutes.monthlyReport` | `/report/monthly` | `MonthlyReportScreen` | Month picker, summary cards, pie chart, bar chart |
| `AppRoutes.settings` | `/settings` | `SettingsScreen` | Profil, app settings, logout |

**Navigasi:** `context.go(AppRoutes.xxx)` atau `context.push(AppRoutes.xxx, extra: entity)` untuk page/deep-link flows. Tab dashboard memakai local selected-index state dan tidak mendorong route.

---

## DATABASE TABLE (Supabase)

| Tabel | PK | Soft Delete | Kolom Penting |
|---|---|---|---|
| `users` | `user_id` | `is_active=false` | `email`, `display_name` |
| `cashbooks` | `cashbook_id` | `is_deleted=true` | `user_id`, `cashbook_name`, `currency`, `is_default` |
| `wallets` | `wallet_id` | `is_active=false` | `cashbook_id`, `type`, `wallet_name`, `bank_name`, `account_number`, `initial_balance`, `current_balance(BIGINT)`, `sort_order` |
| `categories` | `category_id` | — | `cashbook_id(nullable)`, `type`, `category_name`, `icon`, `color`, `is_system`, `sort_order` |
| `transactions` | `transaction_id` | `is_deleted=true` | `cashbook_id`, `wallet_id`, `category_id`, `type`, `amount(BIGINT IDR)`, `name`, `notes`, `transaction_date` |
| `transfers` | `transfer_id` | — | `cashbook_id`, `from_wallet_id`, `to_wallet_id`, `amount(BIGINT IDR)`, `transfer_date` |

---

## STATUS FITUR

| Fitur | Status | Catatan |
|---|---|---|
| **Auth (Landing/Login/Register)** | **✅ Lengkap** | Landing screen + anim, sign in/up, email verification handling, explicit redirect ke dashboard |
| **Dashboard + Transaction List** | **✅ Lengkap** | Four in-place tabs, current-vs-scheduled balance projection, month navigation, accessible vertical wallets, and four history segments including month-scoped transfer |
| Cashbook CRUD | ✅ Lengkap | |
| Wallet CRUD + Detail | ✅ Lengkap | |
| Transaksi CRUD + Detail | ✅ Lengkap | Sequential add income/expense; `/transactions/form` tetap edit; name-null fallback diaudit |
| Transfer antar wallet | ✅ Lengkap | Sequential add at `/transfer`, history at `/transfer/history`, repository/provider refresh tetap terpasang |
| Laporan / Report | ✅ P0-P2 | Month picker, summary cards, pie chart (kategori), bar chart (tren 12 bulan) |
| Settings | ✅ P0 | Profil akun, ubah password, mode tema, default cashbook, about, logout |
| Recurring Transactions | ⏳ Belum | Entity ada, tidak ada repo/screen |
| Local DB (Drift) | ⏳ Belum | Dependency ada, belum digunakan |

---

## PROVIDER DEPENDENCIES — Diagram

```
┌─ Tier 1: Core DI
│  ├─ supabaseClientProvider
│  ├─ cashbookRepositoryProvider
│  ├─ walletRepositoryProvider
│  ├─ transactionRepositoryProvider
│  └─ settingsRepositoryProvider
│
├─ Tier 2: Auth
│  ├─ authStateProvider
│  └─ currentUserProvider
│
├─ Tier 3: Setup & State
│  ├─ setupInProgressProvider (StateProvider - suppress redirect)
│  ├─ activeCashbookProvider (StateProvider - manual set or auto by defaultCashbookProvider)
│  ├─ appThemeModeProvider (StateProvider - theme sistem/terang/gelap)
│  └─ defaultCashbookProvider ← WATCHES: currentUserProvider, cashbookRepositoryProvider
│                              ← AUTO-SETS: activeCashbookProvider
│
└─ Tier 4: Data (depends on activeCashbookProvider)
   ├─ cashbooksProvider
   ├─ walletsProvider ← WATCHES: activeCashbookProvider
   ├─ categoriesProvider ← by cashbookId
   ├─ transactionsProvider ← WATCHES: transactionFilterProvider, selectedMonthProvider
   ├─ futureTransactionProjectionProvider ← active cashbook scheduled income/expense
   ├─ monthlySummaryProvider
   ├─ totalBalanceProvider ← sums walletsProvider
   ├─ transfersProvider
   └─ selectedMonthTransfersProvider ← WATCHES: selectedMonthProvider
```

**Critical:** `defaultCashbookProvider` auto-sets `activeCashbookProvider` pada first load, kemudian semua data providers menggunakannya.

## POLA PROVIDER — Cepat Referensi

### Pola 1: Menambah Provider Baru
```dart
// Untuk data fetch
final xxxProvider = FutureProvider<XxxEntity>((ref) async {
  final repo = ref.watch(xxxRepositoryProvider);
  return repo.getXxx();
});

// Untuk state UI
final xxxStateProvider = StateProvider<XxxState>((ref) => initialValue);

// Watch dan gunakan di widget
final xxxAsync = ref.watch(xxxProvider);

// Setelah mutasi, invalidate
ref.invalidate(xxxProvider);
```

### Pola 2: Invalidate After Mutation (Transaction CRUD)
```dart
// Setelah create/update/delete transaksi
ref.invalidate(transactionsProvider);         // list refresh
ref.invalidate(walletsProvider);              // balance update
ref.invalidate(totalBalanceProvider);         // dashboard refresh
ref.invalidate(monthlySummaryProvider);       // summary recalc
ref.invalidate(futureTransactionProjectionProvider); // scheduled-balance refresh
ref.invalidate(cashbookBalanceProvider(cashbookId)); // stable cashbook-row balance
ref.invalidate(categoriesProvider);           // jika ada perubahan kategori
```

**Providers yang perlu di-invalidate setelah mutasi transaksi:**
`transactionsProvider`, `walletsProvider`, `totalBalanceProvider`, `monthlySummaryProvider`, `futureTransactionProjectionProvider`, dan `cashbookBalanceProvider(cashbookId)`

---

## CATEGORY ICONS (string → IconData di TransactionTile)

`makanan`, `minuman`, `transportasi`, `bensin`, `parkir`, `belanja`, `kebutuhan_harian`, `tagihan`, `langganan`, `hiburan`, `kesehatan`, `pendidikan`, `gaji`, `hadiah`, `donasi`, `bisnis`, `investasi`, `transfer`, `lainnya`

---

## COMMON PATTERNS — Copy-Paste Ready

### Pattern 1: Menambah Screen Baru
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class XxxScreen extends ConsumerStatefulWidget {
  const XxxScreen({super.key});

  @override
  ConsumerState<XxxScreen> createState() => _XxxScreenState();
}

class _XxxScreenState extends ConsumerState<XxxScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch providers
    final xxxAsync = ref.watch(xxxProvider);

    // Handle state: loading, error, data
    return xxxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (xxx) {
        if (xxx.isEmpty) {
          return Center(child: Text('Data kosong'));
        }
        return ListView(...); // UI Anda
      },
    );
  }
}
```

### Pattern 2: Error Handling (SnackBar vs Inline)
```dart
// ✅ SnackBar: BottomSheet, drawer, tak-overlay (visible)
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Gagal!'), backgroundColor: AppColors.error),
);

// ✅ Inline Text: AlertDialog (SnackBar behind overlay = invisible)
String? _errorMessage;
if (_errorMessage != null) {  
  Text(_errorMessage!, style: TextStyle(color: AppColors.error));
}

// ✅ Console: SEMUA catch blok
debugPrint('Error context: $e');
```

### Pattern 3: Amount Input Formatting
```dart
TextField(
  keyboardType: TextInputType.number,
  onChanged: (value) {
    setState(() {
      _amount = int.tryParse(value.replaceAll('.', '')) ?? 0;
    });
  },
  decoration: InputDecoration(prefixText: 'Rp '),
)
```

### Pattern 4: Mutation dengan Invalidate
```dart
Future<void> _createTransaction() async {
  try {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.createTransaction(...);
    // ✅ Invalidate SETELAH sukses
    ref.invalidate(transactionsProvider);
    ref.invalidate(totalBalanceProvider);
    ref.invalidate(monthlySummaryProvider);
    if (mounted) context.pop();
  } catch (e) {
    debugPrint('Error: $e');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

## AUTH & NAVIGATION DETAILS

**Redirect Logic (GoRouter dispatch):**
- App starts at `/splash` (loading spinner during auth init)
- Auth loading state → stay at splash
- Auth resolved + logged in → redirect to `/dashboard`
- Auth resolved + not logged in → redirect to `/landing` 
- Try to access `/dashboard` without login → redirect to `/landing`
- On public routes (landing/login/register) while logged in → redirect to `/dashboard`

**Auth Action Flow:**
- `signInWithPassword()` checks `result.session != null` then explicit `context.go(dashboard)` + 300ms delay
- `signUp()` same flow, but if session is null (email verification required) show message and navigate to landing
- All Supabase errors logged to console + shown in SnackBar (detect patterns like "Invalid credentials", "already registered")

**Locale Data Initialization:** CRITICAL
- Must call `await initializeDateFormatting('id_ID', null)` in `main()` before `runApp()`
- Required because DateFormatter uses intl package with id_ID locale
- Missing init → `LocaleDataException` on all date formatting calls

---

## QUICK DEBUG CHECKLIST

### ❓ Provider/Data Issues

| Problem | Root Cause | Solution |
|---|---|---|
| **Provider not updating / Widget not rebuilding** | Forgot `ref.invalidate()` after mutation | Setelah create/update/delete, always invalidate related providers |
| **Data kosong padahal sudah create** | Provider belum di-invalidate atau loading cache lama | UI: cek `AsyncValue.when()` sedang loading? Try: `ref.refresh(xxx)` |
| **`activeCashbookProvider` null** | `defaultCashbookProvider` belum run atau no default cashbook exists | Dashboard: pastikan watch `defaultCashbookProvider` di `build()` |
| **walletsProvider selalu empty** | watching wrong provider atau `activeCashbookProvider` null | Check: is `activeCashbookProvider` set? Does wallet query filter by cashbook_id? |

### ❓ Navigation & Router Issues

| Problem | Root Cause | Solution |
|---|---|---|
| **Auto-redirect ke dashboard saat setup wizard** | Router redirect not suppressed | Check: `setupInProgressProvider` flag set to true before showing dialog? |
| **Setup wizard memutup sendiri setelah create** | Widget unmounted sebelum onComplete dipanggil | Check: `onComplete()` di luar `try/finally`? Use `if (mounted)` sebelum context access |
| **Cannot access context after async** | Widget unmounted during await | Pattern: set state di try/finally, call callback di luar |
| **Redirect loop landing → login** | Auth state emit multiple times | Check: goRouterProvider only has ONE listener to `authStateProvider` |

### ❓ UI/Display Issues

| Problem | Root Cause | Solution |
|---|---|---|
| **SnackBar tidak terlihat** | Rendered di balik overlay (dialog/bottom sheet) | Gunakan inline Text widget di dalam dialog content |
| **Konten widget hilang/tidak terlihat (padahal tidak transparan)** | `BoxDecoration` dengan `Border()` sisi berbeda lebar (misal left=4px, others=1px) + `borderRadius` → Flutter membuat clip path salah, seluruh konten ter-clip | Pisahkan left accent bar sebagai `Container(width: 4, color: ...)` di dalam `Row`, gunakan `Border.all()` untuk outline + `clipBehavior: Clip.antiAlias` |
| **TextFormField validation error tidak muncul** | Validator return non-null tapi error tidak trigger | Check: did you call `_formKey.currentState?.validate()`? |
| **Amount field: currency format ugly** | Int to String without formatting | Use `CurrencyFormatter.format(amount)` saat display |

### ❓ Database/Supabase Issues

| Problem | Root Cause | Solution |
|---|---|---|
| **RLS policy error saat insert** | User tidak punya permission di sheet | Check RLS policy di Supabase Dashboard → auth rules |
| **Email "already registered" setelah clear test** | Auth.users (managed by Supabase) separate dari app `users` table | Manually delete user di Supabase Dashboard → Authentication → Users |
| **"is_deleted=true" soft delete jangan disertakan** | Query tidak include `where is_deleted=false` | Check: repository query all include `.eq('is_deleted', false)` |

---

## SPRINT LOG & CHECKLIST

### ✅ **Sprint 4.8 — Comfort Pipeline Improvements DONE (June 30, 2026)**
**Items:**
- [x] Pindahkan readiness check loading pipeline ke `initState` di `lib/presentation/screens/splash/loading_screen.dart` agar tidak dijadwalkan ulang dari `build()`.
- [x] Kurangi kerja ulang di transaction list dengan menghapus sort redundant pada data yang sudah diurutkan oleh repository di `lib/presentation/screens/transaction/transaction_list_screen.dart`.
- [x] Tambah `transactionListItemsProvider` untuk precompute grouping transaksi per tanggal sebelum masuk ke build UI.
- [x] Pecah [dashboard_screen.dart](lib/presentation/screens/dashboard/dashboard_screen.dart) menjadi bootstrap, scaffold, body, dan consumer widgets kecil agar rebuild lebih terlokalisasi.
- [x] Pecah [monthly_report_screen.dart](lib/presentation/screens/report/monthly_report_screen.dart) menjadi body consumer terpisah dan ganti loading spinner dengan placeholder visual yang lebih halus.
- [x] Pertahankan behavior existing sambil menurunkan rebuild overhead dan memperbaiki perceived responsiveness.

### ✅ **Sprint 4.9 — Documentation Sync & UX Polish DONE (June 30, 2026)**
**Items:**
- [x] Sinkronkan [docs/state-management.md](docs/state-management.md) untuk `transactionListItemsProvider` dan split loading pipeline.
- [x] Sinkronkan [docs/feature-modules.md](docs/feature-modules.md) untuk loading placeholder dashboard, wallet detail, transaction list, dan reports.
- [x] Sinkronkan [docs/project-map.md](docs/project-map.md) untuk `LoadingScreen` dan derived transaction list grouping.
- [x] Update ringkasan file/class di `.github/PROJECT_DICTIONARY.md` agar cocok dengan state codebase terbaru.

### ✅ **Sprint 4.10 — Palette Refresh DONE (June 30, 2026)**
**Items:**
- [x] Ganti palette global di [lib/core/constants/app_colors.dart](lib/core/constants/app_colors.dart) ke dark teal, lavender, lime, mint, peach, dan neutrals baru.
- [x] Sesuaikan [lib/app/theme.dart](lib/app/theme.dart) agar `ColorScheme` Material 3 memakai seed baru dan aksen yang lebih selaras.
- [x] Terapkan aksen palette baru di [lib/presentation/screens/splash/loading_screen.dart](lib/presentation/screens/splash/loading_screen.dart) dan [lib/presentation/screens/auth/landing_screen.dart](lib/presentation/screens/auth/landing_screen.dart).
- [x] Sinkronkan dokumentasi palette di [docs/project-map.md](docs/project-map.md) dan file dictionary ini.

### ✅ **Sprint 4.11 — Provider Type Cleanup DONE (July 5, 2026)**
**Items:**
- [x] Ubah `sharedPreferencesProvider` menjadi `Provider<Future<SharedPreferences>>` dan sesuaikan `ThemeModeNotifier` agar menerima future langsung di [lib/presentation/providers/providers.dart](lib/presentation/providers/providers.dart).
- [x] Sinkronkan dokumentasi state-management di [docs/state-management.md](docs/state-management.md) agar tipe `appThemeModeProvider` dan provider prefs sesuai kode.
- [x] Update file map provider di `.github/PROJECT_DICTIONARY.md` supaya mencerminkan persistensi theme mode lewat `SharedPreferences`.

### ✅ **Sprint 4.12 — Dark Palette Propagation DONE (July 5, 2026)**
**Items:**
- [x] Propagasi palette dark ke layar inti yang sebelumnya masih menahan warna light: [loading_screen.dart](lib/presentation/screens/splash/loading_screen.dart), [dashboard_screen.dart](lib/presentation/screens/dashboard/dashboard_screen.dart), [transaction_list_screen.dart](lib/presentation/screens/transaction/transaction_list_screen.dart), [monthly_report_screen.dart](lib/presentation/screens/report/monthly_report_screen.dart).
- [x] Update widget reusable [transaction_tile.dart](lib/presentation/widgets/transaction_tile.dart) agar kartu transaksi mengikuti `ColorScheme` tema aktif.
- [x] Update layar detail [transaction_detail_screen.dart](lib/presentation/screens/transaction/transaction_detail_screen.dart) dan [wallet_detail_screen.dart](lib/presentation/screens/wallet/wallet_detail_screen.dart) supaya header, card, dan loading state memakai palette gelap.

### ✅ **Sprint 4.13 — Dual Palette Refresh DONE (July 5, 2026)**
**Items:**
- [x] Perbarui [lib/core/constants/app_colors.dart](lib/core/constants/app_colors.dart) agar nilai light/dark mengikuti palette baru yang diminta.
- [x] Perbarui [lib/app/theme.dart](lib/app/theme.dart) supaya `ColorScheme` dark memakai container/error baru dari palette dan tetap menjaga light mode.
- [x] Jadikan [lib/presentation/screens/splash/loading_screen.dart](lib/presentation/screens/splash/loading_screen.dart) adaptif terhadap mode terang dan gelap agar splash tidak menahan warna dark di light mode.

### ✅ **Sprint 4.14 — Android UI Audit & Documentation DONE (August 1, 2026)**
**Items:**
- [x] Tambahkan [docs/ui-analysis-android.md](docs/ui-analysis-android.md) yang mendokumentasikan audit UI Android per layar, dark mode, kontras, edge-to-edge, responsiveness, aksesibilitas, navigasi, branding, dan izin Android.
- [x] Tambahkan laporan UI Android ke indeks dokumentasi di `AGENTS.md`.
- [x] Verifikasi statis dengan `dart analyze`: tidak ada error kompilasi yang dilaporkan; masih terdapat 48 warning/info yang perlu ditindaklanjuti.
- [x] Catat bahwa aplikasi saat ini hanya membutuhkan `android.permission.INTERNET`; tidak ada izin runtime tambahan untuk fitur yang tersedia.

### ✅ **Sprint 4.16 — Android UI Validation DONE (August 1, 2026)**
**Items:**
- [x] Flutter 3.38.7 / Dart 3.10.7 dan ADB 35.0.2 tervalidasi; perangkat `23122PCD1G` terhubung pada Android 16/API 36, 1220 × 2712, density 480.
- [x] `flutter build apk --debug --no-pub` berhasil; APK diinstal dengan `adb install -r` tanpa menghapus data aplikasi.
- [x] Verifikasi light/dark portrait: dashboard, transaksi, detail transaksi, report, settings, transfer, dan form pengeluaran; keyboard numerik juga diuji.
- [x] Screenshot dan UI Automator semantics disimpan sementara di folder temp host, tidak masuk repository.
- [x] Logcat 2.000 baris terakhir tidak menunjukkan crash, `FATAL EXCEPTION`, atau ANR; proses aplikasi tetap hidup.
- [x] Permission paket terpasang hanya `android.permission.INTERNET`; tidak ada runtime permission yang perlu diberikan pengguna.
- [x] `flutter test --no-pub` lulus; `dart analyze` tidak menemukan error kompilasi tetapi masih melaporkan 50 warning/info.
- [ ] Matrix landscape, gesture navigation, font scale besar, dynamic color, dan responsive filter masih backlog.

### ✅ **Sprint 4.17 — UI Foundation DONE (August 1, 2026)**
**Items:**
- [x] Tambahkan design tokens const untuk spacing, radius, border, elevation, icon, component height, dan motion.
- [x] Refactor palette dan semantic color light/dark tanpa menghapus nama constant lama; lime tidak lagi menjadi primary dark.
- [x] Refactor Material 3 `ThemeData` terpusat untuk surface, navigation, card, form, button, FAB, segmented control, sheet, dialog, snackbar, dan list tile.
- [x] Tambahkan `AppSectionHeader` dan `MoneyMetric` sebagai reusable presentation widgets tanpa business logic.
- [x] Provider, repository, entity, model, query, route, dan kontrak `state.extra` tidak diubah.
- [x] `flutter analyze` selesai tanpa error kompilasi baru; 50 issue lint/info lama masih tercatat.
- [ ] Refactor screen Dashboard, Transaction History, Monthly Report, wallet, form, transfer, settings, dan auth ditunda ke fase berikutnya.

### ✅ **Sprint 4.18 — Transaction History Filter Fix (August 1, 2026)**
**Items:**
- [x] Ganti gesture custom pada filter tipe dengan `ChoiceChip` Material agar target tap dan state selected konsisten.
- [x] Ganti pemilih bulan pada grid dengan `TextButton` Material agar pemilihan bulan memiliki semantics dan callback tombol yang jelas.
- [x] Susun filter tipe dengan `Wrap` dan tempatkan tombol bulan pada baris penuh terpisah agar tidak terklip pada lebar 360–412 dp.
- [x] Jadikan `transactionFilterProvider` sebagai sumber state filter yang ditampilkan dan pertahankan seluruh batas tanggal/category/wallet saat tipe berubah.
- [x] Invalidate query transaksi setelah perubahan bulan atau tipe tanpa mengubah provider, repository, entity, query, atau database.
- [x] `flutter test --no-pub` lulus; full `flutter analyze` masih mencatat 50 issue lama.
- [ ] Verifikasi tap langsung di Android tertunda karena Android SDK dan perangkat tidak terdeteksi pada environment saat ini.

### ✅ **Sprint 4.15 — UI P0 Implementation DONE (August 1, 2026)**
**Items:**
- [x] Tambahkan semantic foreground colors dan perbaiki light/dark `ColorScheme` di [app_colors.dart](lib/core/constants/app_colors.dart) dan [theme.dart](lib/app/theme.dart).
- [x] Aktifkan edge-to-edge Android secara terkontrol, konfigurasi system bar, dan tambahkan `SafeArea`/inset protection pada layar utama serta form.
- [x] Perbaiki kontras dark mode pada laporan, daftar/detail transaksi, wallet detail, transfer, dan reusable `TransactionTile`.
- [x] Perbaiki gradient/foreground wallet detail, transfer button, transaction form button, filter/toggle target sentuh, serta date picker locale Indonesia.
- [x] Hilangkan dead CTA prioritas: lupa password kini mengirim email reset melalui repository, Google Sign-In ditandai belum tersedia, terms tidak lagi memiliki tap handler kosong, dan “Lihat Semua” membuka daftar transaksi.
- [x] Perluas auth guard ke seluruh route data yang membutuhkan session.
- [x] `dart analyze` tidak menemukan error kompilasi; masih terdapat 50 warning/info lint/deprecation. Smoke test `flutter test --no-pub` kemudian lulus pada validasi langsung.
- [x] Uji visual langsung di perangkat Android diselesaikan pada Sprint 4.16.

### ✅ **Sprint 4.5 — Transaction Detail Hydration Fix DONE (April 8, 2026)**
**Items:**
- [x] Perbaiki parser `TransactionModel.fromJson()` agar membaca hasil join nested Supabase (`wallets`, `categories`) di `lib/data/models/models.dart`
- [x] Tambah `transactionDetailProvider(transactionId)` untuk fetch ulang detail transaksi dari database di `lib/presentation/providers/providers.dart`
- [x] Update `TransactionDetailScreen` agar memakai data provider detail (bukan hanya payload route), sehingga kategori/dompet/keterangan tampil akurat di `lib/presentation/screens/transaction/transaction_detail_screen.dart`
- [x] Update dokumentasi terkait di `docs/state-management.md` dan `docs/feature-modules.md`

### ✅ **Sprint 4.4 — Settings P0 Complete (April 2, 2026)**
**Items:**
- [x] Tambah `SettingsScreen` di `lib/presentation/screens/settings/settings_screen.dart`
- [x] Tambah `SettingsRepository` untuk update profil, ubah password, dan logout
- [x] Tambah `settingsRepositoryProvider` dan `appThemeModeProvider`
- [x] Daftarkan GoRoute `/settings` di router
- [x] Integrasi `themeMode` di `main.dart` agar bisa switch Sistem/Terang/Gelap
- [x] Tambah fitur P0: edit nama, email readonly, ubah password, set default cashbook, about/version, logout

### ✅ **Sprint 4.3 — Transfer UX & Nominal Input Fix (March 31, 2026)**
**Items:**
- [x] Setelah transfer sukses, langsung navigasi ke homepage/dashboard (`context.go(AppRoutes.dashboard)`) di `lib/presentation/screens/transfer/transfer_screen.dart`
- [x] Ubah warna teks nominal input pada form pemasukan/pengeluaran menjadi hitam di `lib/presentation/screens/transaction/transaction_form_screen.dart`
- [x] Aktifkan autofocus pada field nominal agar keyboard langsung siap mengetik saat halaman form transaksi dibuka

### ✅ **Sprint 4.2 — Supabase DNS/Network Fix (March 31, 2026)**
**Items:**
- [x] Tambah permission internet di `android/app/src/main/AndroidManifest.xml`
- [x] Validasi file AndroidManifest tidak ada error
- [x] Root cause yang diperbaiki: build main/release belum mendeklarasikan `android.permission.INTERNET`

### ✅ **Sprint 4.1 — Transfer Antar Wallet DONE (March 30, 2026)**
**Items:**
- [x] Tambah screen transfer `lib/presentation/screens/transfer/transfer_screen.dart` (form + riwayat transfer)
- [x] Tambah method repository `createTransfer()` dan `getTransfersByCashbook()` di `TransactionRepository`
- [x] Sambungkan `transfersProvider` ke repository (hapus query raw dari provider)
- [x] Tambah GoRoute `/transfer` di `lib/app/router.dart`
- [x] Aktifkan aksi Transfer di bottom sheet dashboard (`lib/presentation/screens/dashboard/dashboard_screen.dart`)
- [x] Invalidation setelah create transfer: `transfersProvider`, `walletsProvider`, `totalBalanceProvider`
- [x] Update dokumentasi terkait: `docs/feature-modules.md`, `docs/navigation-flow.md`, `docs/project-map.md`, `docs/architecture.md`, `AGENTS.md`

### ✅ Sprint 1 — Foundation Complete
- Project structure + Supabase setup
- Database schema + Entities
- Repositories + Models
- Riverpod providers
- Cashbook/Wallet/Transaction CRUD screens

### ✅ **Sprint 2 — Auth & Dashboard DONE (March 11)**  
**Items:**
- [x] Landing screen with fade+slide animation
- [x] Login screen with validation + error handling
- [x] Register screen with step indicator + terms checkbox
- [x] Router refactor: splash → landing → dashboard flow
- [x] Dashboard with balance card, summary, wallet carousel
- [x] Transaction list with filters + grouping
- [x] Fixed LocaleDataException
- [x] Improved auth redirect (explicit + 300ms delay)
- [x] Updated PROJECT_DICTIONARY.md

### ✅ **Sprint 2.1 — UX & Visual Improvements DONE (March 11)**  
**Items:**
- [x] **First-time setup wizard** — Auto-show dialog untuk cashbook & wallet creation setelah register
- [x] **Amount field readability** — Text shadow on number input untuk better contrast white-on-colored-bg
- [x] **Transaction list visual diff** — Left border color by type (income=green, expense=red)

### ✅ **Sprint 2.2 — Bug Fixes DONE (March 11)**  
**Items:**
- [x] **Fix crash setup wizard** — `_createCashbook` & `_createWallet`: `widget.onComplete()` dipindah ke luar `try/finally` agar `setState` tidak dipanggil setelah dialog di-pop (`register_screen.dart`)
- [x] **Improve email error detection** — Tambah cek `already been registered` & `user already exists` selain `already registered` (`register_screen.dart`)
- [x] **Catatan**: "Email sudah terdaftar" setelah clear DB → Supabase Auth (`auth.users`) TERPISAH dari tabel app. Hapus user via Supabase Dashboard → Authentication → Users

### ✅ **Sprint 2.4 — Full Architecture Documentation DONE (March 11, 2026)**
**Items:**
- [x] Created `AGENTS.md` — top-level AI agent entry point with orientation guide, feature status, task recipes
- [x] Created `docs/architecture.md` — Clean Architecture layers, module interaction diagram, design decisions, init sequence
- [x] Created `docs/project-map.md` — full directory map, key files, DB table reference, feature location quick lookup
- [x] Created `docs/feature-modules.md` — feature-by-feature breakdown with status, files, UI components, data layer
- [x] Created `docs/state-management.md` — all providers by tier, mutation pattern, invalidation table, special patterns
- [x] Created `docs/navigation-flow.md` — full route table, screen hierarchy, auth redirect logic, navigation patterns
- [x] Updated `.github/copilot-instructions.md` — added docs/ references, removed outdated stub status, updated docs section

### ✅ **Sprint 2.3 — Cashbook Setup & Default Flow DONE (March 11)**
**Items:**
- [x] **setupInProgressProvider** — New StateProvider to suppress router redirect during onboarding (prevent early dashboard redirect)
- [x] **defaultCashbookProvider** — New FutureProvider: auto-loads default cashbook & auto-sets activeCashbookProvider
- [x] **CashbookRepository.createCashbook()** — Updated: `setAsDefault=true` parameter so first cashbook is active
- [x] **CashbookRepository methods** — Added: `getDefaultCashbook()`, `getUserCashbooks()`
- [x] **DashboardScreen** — Now watches `defaultCashbookProvider` to auto-load default cashbook on entry
- [x] **Updated PROJECT_DICTIONARY.md** — Added provider dependency map, common patterns, debug checklist

### ✅ **Sprint 2.5 — UI/UX Fixes DONE (March 11, 2026)**
**Items:**
- [x] **Fix nav bar highlight** — `context.push().then(...)` untuk reset `_selectedNavIndex = 0` saat kembali dari halaman yang di-push (`dashboard_screen.dart`)
- [x] **FAB label** — Ganti `FloatingActionButton` ke `FloatingActionButton.extended` dengan label "Transaksi Baru" (`dashboard_screen.dart`)

### ✅ **Sprint 2.5 — Bug Fix TransactionTile DONE (March 11, 2026)**
**Items:**
- [x] **Fix konten TransactionTile hilang** — Root cause: `Border()` dengan sisi berbeda lebar + `borderRadius` menyebabkan Flutter clip seluruh konten tile
- [x] **Refactor left accent bar** — Dari `BorderSide(width:4)` ke `Container(width:4, color:typeColor)` sebagai child pertama di `IntrinsicHeight` Row
- [x] **Updated PROJECT_DICTIONARY.md** — Tambah debug entry baru di UI/Display Issues

### ✅ **Sprint 3.4 — Loading Screen & Race Condition Fix DONE (March 11, 2026)**
**Items:**
- [x] Buat `lib/presentation/screens/splash/loading_screen.dart` (`LoadingScreen`) — branded loading screen (logo, nama app, spinner)
- [x] `LoadingScreen` watches `defaultCashbookProvider`, `cashbooksProvider`, `walletsProvider`; navigasi ke Dashboard hanya setelah ketiganya resolve
- [x] Root cause fix: `walletsProvider` return `AsyncData([])` langsung saat `activeCashbook == null` sebelum `defaultCashbookProvider` resolve — diatasi dengan kondisi `defaultCashbook.hasValue && !wallets.isLoading`
- [x] Tambah `AppRoutes.loading = '/loading'` + GoRoute di `router.dart`
- [x] Router redirect: `splash → /loading` (authenticated) bukan langsung ke `/dashboard`; `/loading` di-guard agar hanya bisa diakses saat login
- [x] Router redirect: login dari halaman publik (landing/login/register) → `/loading` (bukan `/dashboard`)
- [x] `_TutorialOverlay` hardened: cek `cashbooksAsync.isLoading` — jangan tampil saat loading; cek `activeCashbook != null` sebelum evaluasi step2
- [x] Login & Register → `context.go(AppRoutes.loading)` setelah auth berhasil

### ✅ **Sprint 3.3 — Tutorial Overlay & Auto-Load Cashbook DONE (March 11, 2026)**
**Items:**
- [x] Hapus auto-create cashbook dari `register_screen.dart`; hapus import `CashbookRepository`
- [x] Tambah `getEarliestCashbook(userId)` di `CashbookRepository` (order `created_at ASC`, `maybeSingle`)
- [x] Update `defaultCashbookProvider` → gunakan `getEarliestCashbook` (bukan `is_default=true`)
- [x] `cashbook_form_screen.dart`: tambah `ref.invalidate(defaultCashbookProvider)` setelah save
- [x] Ganti `_SetupBanner` + `_SetupGuideSheet` + `_WalletTypeButton` di dashboard dengan `_TutorialOverlay` (fullscreen semi-transparent)
- [x] `_TutorialOverlay`: reaktif, watch `cashbooksProvider` + `walletsProvider`; step 1 → `/cashbooks/form`, step 2 → `/wallets/form`; setelah `/cashbooks/form` pop, invalidate `defaultCashbookProvider` untuk set active cashbook

### ✅ **Sprint 3.2 — Remove Wizard, Auto Cashbook DONE (March 11, 2026)**
**Items:**
- [x] **Hapus setup wizard** — `_FirstTimeSetupDialog`, `_WalletSetupSheet`, `_WalletTypeOption`, `_showFirstTimeSetupDialog()`, `_showWalletSetupSheet()` dihapus dari `register_screen.dart`
- [x] **Auto-create cashbook** — setelah register sukses, otomatis buat cashbook `'Keuangan {firstName}'` dengan `setAsDefault: true`
- [x] **Auto-set active** — `activeCashbookProvider` langsung di-set + invalidate `cashbooksProvider`/`defaultCashbookProvider` sebelum go to dashboard
- [x] **Default selalu terbuka** — `defaultCashbookProvider` + `is_default=true` di Supabase menjamin cashbook terbuka otomatis setiap buka app

### ⏳ Sprint 3.3 — Reports & Settings (Sisa)
**Items:**
- [x] **Repository methods** — `getMonthlySummaryForReport()`, `getCategoryBreakdownByMonth()`, `getYearlyTrendData()` di `TransactionRepository`
- [x] **Providers** — `reportMonthProvider`, `reportMonthlySummaryProvider`, `reportCategoryBreakdownProvider`, `reportYearlyTrendProvider`
- [x] **MonthlyReportScreen** — `lib/presentation/screens/report/monthly_report_screen.dart`
- [x] **P0: Month picker** — Chevron prev/next + grid dialog (bulan × tahun)
- [x] **P0: Summary cards** — Income card, Expense card, Surplus/Defisit net card
- [x] **P1: Pie chart** — Distribusi kategori (expense/income toggle, touch tooltip, legend list)
- [x] **P2: Bar chart** — Tren 12 bulan (grouped bar, income+expense, highlighted bulan aktif)
- [x] **GoRoute** — `/report/monthly` terdaftar di `router.dart`
- [x] **Akses** — Bottom nav Dashboard index 2 sudah mengarah ke laporan

### ⏳ Sprint 3.2 — Reports & Settings (Sisa)
- [ ] Settings page
- [ ] Recurring transactions
- [ ] Update PROJECT_DICTIONARY after completion

### ✅ **Sprint 4.7 — Provider Orchestration Cleanup DONE (June 30, 2026)**
**Items:**
- [x] Pindahkan fetch cashbooks, wallets, total balance, monthly summary, dan transfer history dari `lib/presentation/providers/providers.dart` ke repository layer.
- [x] Pertahankan `providers.dart` sebagai orchestration layer untuk state, invalidation, dan dependency wiring.
- [x] Tambahkan helper internal untuk normalisasi tanggal dan agregasi integer di `lib/data/repositories/cashbook_wallet_repository.dart`.

### ⏳ Sprint 4 — Polish & Advanced
- [x] Transfer between wallets
- [ ] Data export (CSV, PDF)
- [ ] Dark mode
- [ ] Local cache (Drift)
- [ ] Notification reminders
- [ ] Cashbook switcher UI improvements
- [ ] Update PROJECT_DICTIONARY after completion

---


### ? **Sprint 4.6 � Fix Wallet Balance on Delete DONE (May 8, 2026)**
**Items:**
- [x] Fix bug: Wallet balance did not update when a transaction is soft-deleted.
- [x] Modified deleteTransaction in lib/data/repositories/cashbook_wallet_repository.dart to manually adjust current_balance on the source wallet.

### Sprint 4.19 - Dashboard Shape Rework DONE (August 1, 2026)
**Items:**
- [x] Terapkan shape scale terpusat untuk small/control/card/prominent radius, tanpa menghapus alias radius lama.
- [x] Refactor Dashboard menjadi hero saldo kontinu tanpa border, satu surface tonal untuk ringkasan bulanan, dan wallet card filled tanpa outline.
- [x] Buat wallet carousel responsif dengan preview yang disengaja, ellipsis aman untuk nama panjang, dan ruang cukup pada text scale 1.3.
- [x] Gunakan Material 3 `NavigationBar` serta pertahankan extended FAB, provider, route, loading/error state, dan tutorial behavior.
- [x] Uji widget sementara lulus untuk light/dark, lebar 360/393/412 dp, text scale 1.0/1.3, nilai Rupiah besar, nama wallet panjang, loading, empty, dan error state.
- [x] `dart format`, `flutter test --no-pub`, dan full `flutter analyze` dijalankan; analyzer tetap melaporkan 50 issue lama (49 info, 1 warning), tanpa error baru.
- [ ] Screenshot Android belum tersedia karena environment saat validasi hanya mendeteksi Windows/Chrome/Edge dan tidak memiliki AVD.

### Sprint 4.20 - Transaction History Shape Rework DONE (August 1, 2026)
**Items:**
- [x] Ganti tiga filter outline menjadi satu segmented control tonal dengan selected state semantic dan target sentuh 48 dp.
- [x] Ganti month selector besar ber-outline menjadi toolbar ringkas dengan tombol bulan sebelumnya/berikutnya dan label yang tetap membuka picker.
- [x] Satukan summary pemasukan, pengeluaran, dan selisih dalam satu surface tonal tanpa nested card.
- [x] Ubah date header menjadi typography sederhana dengan divider halus; transaction rows kini flat, compact, dan amount rata kanan.
- [x] Refactor `TransactionTile` dengan opsi focused `dense` dan `showDivider`; provider grouping, filter state, invalidation, formatter, dan route extra tetap dipertahankan.
- [x] Loading, empty, error state, long metadata, nominal besar, light/dark, 360/393/412 dp, dan text scale 1.0/1.3 divalidasi melalui widget test sementara.
- [ ] Screenshot Android belum tersedia karena environment validasi tidak mendeteksi device atau AVD.

### Sprint 4.21 - Monthly Report Shape Rework DONE (August 1, 2026)
**Items:**
- [x] Ganti month selector ber-outline menjadi toolbar tonal ringkas dengan target sentuh Android yang tetap memadai.
- [x] Satukan pemasukan, pengeluaran, dan surplus/defisit dalam satu surface tonal menggunakan `MoneyMetric`.
- [x] Ganti toggle kategori menjadi segmented control terisi dengan semantic color income/expense.
- [x] Kurangi dominasi donut chart, rapikan legend, dan gabungkan kategori kecil menjadi "Lainnya" hanya pada presentation layer.
- [x] Hilangkan nested card dan outline dekoratif dari loading chart serta trend chart; provider, formatter, dan data integer tetap dipertahankan.
- [x] `dart format`, target `dart analyze`, full `flutter analyze`, dan `flutter test --no-pub` dijalankan; tidak ada error atau warning baru dari perubahan Phase 4.
- [ ] Screenshot Android belum tersedia karena environment validasi tidak mendeteksi device atau AVD.

### Sprint 4.22 - Remaining UI Shape Standardization DONE (August 1, 2026)
**Items:**
- [x] Standardisasi wallet dan cashbook list/form: object memakai filled surface, nama dan nominal panjang aman, serta aksi utama memakai Material 3 `FilledButton`.
- [x] Refactor wallet detail dan transaction detail menjadi hero flat tanpa gradient, summary/grouped rows memakai surface tonal, dan detail transaksi mempertahankan aksi destruktif outlined.
- [x] Refactor transaction form dan transfer form: amount/header semantic, field selector tonal, bottom sheet kategori tanpa outline dekoratif, serta riwayat transfer dikelompokkan dalam satu surface.
- [x] Standardisasi settings dan auth screens: section surfaces konsisten, button/input theme terpusat, mode tema dan SharedPreferences, provider, route, serta alur auth tetap dipertahankan.
- [x] `dart format`, `flutter analyze`, `flutter test --no-pub`, dan `flutter build apk --debug` dijalankan; analyzer menyisakan 16 info lama tanpa error atau warning.
- [x] APK debug berhasil dipasang ke perangkat Android `23122PCD1G`; screenshot landing tersedia sebagai pemeriksaan visual dasar.

### Sprint 4.23 - Google OAuth Login DONE (August 1, 2026)
**Items:**
- [x] Aktifkan tombol `Lanjutkan dengan Google` pada `LoginScreen` melalui `supabase_flutter` `OAuthProvider.google`.
- [x] Tambahkan redirect URI `io.supabase.moneytracker://login-callback/` pada konfigurasi aplikasi dan intent filter Android.
- [x] Pertahankan `authStateProvider`, GoRouter redirect, provider lain, repository, entity, query Supabase, dan alur login email/password.
- [x] `dart format`, `flutter analyze`, `flutter test --no-pub`, dan `flutter build apk --debug` dijalankan; analyzer menyisakan 16 info lama tanpa error atau warning baru.
- [ ] Aktivasi end-to-end masih memerlukan konfigurasi Google OAuth Client dan provider Google di Supabase Dashboard.

### Sprint 4.24 - Color Foundation Rework DONE (August 1, 2026)
**Items:**
- [x] Terapkan ColorScheme light/dark warm-neutral dengan deep teal brand, muted coral tertiary, independent secondary, dan charcoal dark surfaces.
- [x] Tambahkan `MoneyTrackerSemanticColors` sebagai ThemeExtension untuk income, expense, transfer, warning, success, dan neutral information.
- [x] Tambahkan deterministic wallet palette dengan foreground pair serta deterministic categorical chart palette.
- [x] Pertahankan constant lama dan `MoneyTrackerColorScheme` compatibility getter; tidak ada provider, route, repository, entity, query, atau business behavior yang diubah.
- [x] Perbarui relevant Material 3 component themes untuk surface, NavigationBar, buttons, segmented control, text selection, dan checkbox.
- [x] `dart format`, `flutter analyze`, `flutter test --no-pub`, dan `flutter build apk --debug` dijalankan; analyzer menyisakan 16 info lama tanpa error atau warning baru.
- [x] Dashboard telah dimigrasikan pada Sprint 4.25; Transaction History dan Monthly Report tetap menunggu review untuk fase berikutnya.

### Sprint 4.25 - Dashboard Color Migration DONE (August 1, 2026)
**Items:**
- [x] Gunakan warm-neutral `surface` untuk halaman Dashboard dan `surfaceContainerLow` untuk app bar agar tidak menyatu dengan balance hero.
- [x] Pertahankan balance hero `primaryContainer`, lalu gunakan surface netral untuk monthly summary dengan nilai pemasukan/pengeluaran dari semantic colors.
- [x] Gunakan semantic income, expense, dan transfer colors pada action sheet tanpa mengubah route atau `state.extra`.
- [x] Terapkan curated wallet palette deterministik berdasarkan tipe wallet dengan foreground pair yang sudah ditentukan untuk light/dark mode.
- [x] Migrasikan avatar, cashbook switcher, tutorial, dan step indicator ke ColorScheme tanpa mengubah provider, loading state, tutorial behavior, atau navigation.
- [x] `dart format`, `flutter analyze`, `flutter test --no-pub`, dan `flutter build apk --debug` dijalankan; analyzer menyisakan 16 info lama tanpa error atau warning baru.
- [x] APK debug berhasil dipasang ke perangkat Android `9cfc535d`; screenshot dicoba setelah wake/unlock, tetapi aplikasi tetap pada splash/loading karena perangkat tidak terhubung jaringan dan sesi Dashboard tidak tersedia.
- [ ] Transaction History dan Monthly Report belum dimigrasikan; menunggu review sebelum Phase 4 dan Phase 5.

### Sprint 4.26 - Icon Foundation and Dashboard DONE (August 3, 2026)
**Items:**
- [x] Tambahkan AppIcons terpusat di lib/presentation/icons/app_icons.dart untuk pasangan nav outlined/rounded, action Dashboard, tipe transaksi, WalletType, alias kategori deterministik, dan fallback aman tanpa mengubah stored keys.
- [x] Migrasikan NavigationBar Dashboard ke pasangan glyph Material Icons Rounded 26 dp dan kartu wallet ke icon langsung berdasarkan tipe wallet; Transaction History tetap deferred.
- [x] Pertahankan guardrail visual: hero saldo dan heading tetap text-only, MoneyMetric tetap text-only, action transaksi memakai icon langsung, dan container tutorial tetap sebagai focal onboarding.
- [x] Perkuat cashbook switcher dengan InkWell pressed state, Tooltip, button semantics, dan tinggi minimum 48 dp; selected state tetap menjadi satu-satunya indikasi icon pada row cashbook.
- [x] Tambahkan focused tests dan real-glyph light/dark goldens; validasi widths 360/393/412, text scale 1.0/1.3, mapping/fallback, semantics, dan full test suite lulus.
- [x] dart format dijalankan pada file Dart milik fase ini; flutter analyze tidak menemukan error/warning (16 info lama tetap ada); git diff --check lulus.
- [ ] Transaction History, Report, Forms, Settings, Auth, dan wallet screens tetap deferred ke fase berikutnya.

### Sprint 4.31 - Dashboard Future Transactions & History DONE (August 8, 2026)
**Items:**
- [x] Izinkan income dan expense dijadwalkan pada tanggal mendatang, tetap memakai kalender lokal; transfer tetap dilarang pada masa depan di draft, picker, dan repository.
- [x] Tambahkan `FutureTransactionProjection` berbasis `int` untuk mengeluarkan seluruh net scheduled income/expense dari saldo trigger, lalu menghitung proyeksi akhir bulan berjalan; transfer tidak ikut dihitung.
- [x] Tampilkan transaksi future secara eksplisit di Dashboard, list, dan detail dengan badge/semantics yang dapat diakses; net-zero scheduled records tetap terlihat.
- [x] Tambahkan `cashbookBalanceProvider` bernama, error saldo yang terlihat pengguna, dan invalidation balance/projection setelah mutasi yang relevan.
- [x] Perluas alias `AppIcons` untuk kategori Indonesia/English umum; semua tile/form/detail memakai mapping pusat serta fallback aman.
- [x] Jadikan `CategoryPickerSheet` shared dan responsif, dengan tambah kategori database-backed yang mengembalikan ID nyata, invalidates provider key yang tepat, lalu memilih kategori baru secara langsung.
- [x] Ubah Dashboard ke kartu wallet vertikal yang dapat diakses, tambah navigasi bulan dengan tombol berikutnya disabled di bulan berjalan, dan sinkronkan month state dengan riwayat transaksi.
- [x] Tambahkan segmen Transfer ke riwayat transaksi; daftar transfer dibatasi bulan aktif dan menjelaskan bahwa transfer tidak mengubah total saldo buku kas. `/transfer/history` tetap terpisah.
- [x] Perbarui `docs/feature-modules.md`, `docs/state-management.md`, `docs/project-map.md`, `docs/ui-analysis-android.md`, dan file dictionary ini.
- [x] Validasi lokal: `flutter pub get`, format check, analyzer, focused tests, full `flutter test` (43 tests), `flutter build apk --debug`, dan `git diff --check` lulus. Analyzer/build memakai konfigurasi dummy lokal yang ignored karena key Supabase tidak tersedia di checkout; file tersebut dihapus sebelum commit.
- [ ] Pemeriksaan perangkat Android/E2E masih memerlukan sesi backend nyata; coverage lokal memakai provider override, focused regression tests, dan golden visual QA.

### Sprint 4.31.1 - Projection & Category Accuracy Fixes DONE (August 8, 2026)
**Items:**
- [x] Samakan populasi proyeksi dengan saldo aktif: query scheduled transaction dibatasi ke `wallet_id` aktif, dan model proyeksi mempertahankan guard set dompet aktif.
- [x] Pusatkan blok icon/teks `CategoryOptionTile` pada tile penuh tanpa menutup selected badge; tambahkan regression layout 360/393/412 dp pada text scale 1.3.
- [x] Turunkan key icon kategori baru dari nama yang dikenal dan gunakan nama kategori sebagai fallback untuk stored key generik/unknown.
- [x] Koreksi tipe provider dan simbol presentation pada dokumentasi agar sesuai dengan implementasi StreamProvider/derived Provider saat ini.
- [x] Validasi retry: format check, analyzer, focused projection/category tests, full `flutter test` (46 tests), `flutter build apk --debug`, dan `git diff --check`; konfigurasi dummy lokal untuk key Supabase dihapus sebelum commit.

### Sprint 4.30 - Bottom Navigation Rework DONE (August 8, 2026)
**Items:**
- [x] Rework Dashboard menjadi shell empat tab lokal: Dashboard, Transaksi, Laporan, dan Pengaturan; perubahan tab mengganti konten di tempat tanpa `context.push`.
- [x] Tambahkan mode embedded pada TransactionListScreen, MonthlyReportScreen, dan SettingsScreen; constructor default tetap menjadi halaman standalone untuk deep link lama.
- [x] Pertahankan route protected `/transactions`, `/report/monthly`, dan `/settings`, auth redirect, provider, repository, onboarding dashboard, serta flow form/detail/transfer.
- [x] Tambahkan regression coverage untuk selected index/in-place tab switching dan registrasi nama route legacy.
- [x] `dart format` dan `flutter test` lulus; analyzer menghasilkan 16 info-level lint lama tanpa error atau warning baru.

### Sprint 4.27 - Sequential Transaction Add Flow DONE (August 5, 2026)
**Items:**
- [x] Tambahkan route eksplisit `/transactions/add/income` dan `/transactions/add/expense`; `/transactions/form` tetap untuk edit; `/transfer` menjadi add flow dan `/transfer/history` tetap discoverable.
- [x] Implementasikan `TransactionDraft` dan `TransferDraft` auto-disposed dengan controller kecil; PageView lima langkah memakai `NeverScrollableScrollPhysics` dan validasi programatik.
- [x] Implementasikan keypad nominal integer Rupiah dengan normalisasi leading zero, backspace aman, target minimal 48 dp, semantics, dan guard overflow PostgreSQL BIGINT.
- [x] Tambahkan selection shell bersama dengan `CategoryOptionTile` dan `WalletOptionCard` purpose-specific; wallet source menampilkan disabled reason untuk saldo kurang dan state khusus kurang dari dua wallet.
- [x] Pertahankan repository/entity/schema serta invalidation mutation yang ada; submit melakukan re-check data live dan mencegah duplicate submit.
- [x] Audit `transaction.name`: model mapping, tile fallback, detail fallback, dan edit form aman untuk null; add flow memakai `name: null` tanpa mengubah historical/edit behavior.
- [x] Tambahkan focused tests, light/dark responsive goldens untuk income/expense/transfer, serta visual QA pada 360/393/412 dp.
- [x] Sinkronkan `docs/navigation-flow.md`, `docs/feature-modules.md`, `docs/state-management.md`, dan file dictionary ini.
- [ ] Android device screenshot/E2E submit masih memerlukan backend/session nyata; local validation memakai provider overrides.

### Sprint 4.28 - Sequential Date Picker Localization DONE (August 5, 2026)
**Items:**
- [x] Reproduksi kegagalan date picker pada flow transaction dan transfer: `DatePickerDialog` tidak memiliki `MaterialLocalizations`.
- [x] Tambahkan konfigurasi `flutter_localizations` bersama dengan locale default/supported Bahasa Indonesia dan delegate Material/Widgets.
- [x] Selaraskan constraint `intl` dengan versi yang dipatok Flutter SDK (`0.20.2`); tidak ada perubahan repository/entity/schema.
- [x] Tambahkan regression test untuk date control transaction, transfer, dan edit existing; pemilihan tanggal sebelumnya mengubah draft/display dan cancel mempertahankan tanggal.
- [x] `dart format`, plain `flutter analyze`, full `flutter test`, dan `git diff --check` lulus.

### Sprint 4.29 - Presentation Regression Fixes DONE (August 6, 2026)
**Items:**
- [x] Hapus hanya drag handle lokal yang redundant dari bottom sheet tambah transaksi Dashboard; `BottomSheetThemeData.showDragHandle: true`, title, tiga aksi, warna, dan routing tetap dipertahankan.
- [x] Ubah `_TypeFilterSegmentedControl` menjadi tiga segmen equal-width tanpa mengubah provider, nilai filter, selected styling/semantics, target 48 dp, InkWell, atau ellipsis.
- [x] Tambahkan regression test terfokus pada lebar 360 dp untuk pengukuran equal thirds, label terpanjang, no-layout-exception, tap interaction, dan `transactionFilterProvider` state.
- [x] Regenerasi serta inspeksi visual golden sheet Dashboard light/dark; hanya dua golden sheet yang berubah dari penghapusan baris redundant.
- [x] Validasi format, focused tests, plain analyzer, full test suite, dan `git diff --check` dijalankan.
