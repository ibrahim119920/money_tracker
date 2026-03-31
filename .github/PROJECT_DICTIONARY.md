# Money Tracker — Project Dictionary
> Panduan referensi cepat untuk Copilot. **Terakhir diperbarui: Maret 31, 2026 (Sprint 4.3 - Transfer UX & Nominal Input Fix)**

> **📖 Dokumentasi Lengkap**: Lihat `AGENTS.md` (entry point) dan folder `docs/` untuk dokumentasi arsitektur yang lebih detail dan AI-friendly.

---

## FILE MAP — Core

| File | Class / Konten |
|---|---|
| `lib/main.dart` | `MoneyTrackerApp`, `_AppInitErrorWidget`, init: `await initializeDateFormatting('id_ID', null)` ⚠️ diperlukan sebelum `runApp()` |
| `lib/app/router.dart` | `AppRoutes` (konstanta path), `goRouterProvider`, `_RouterNotifier`, `_SplashScreen` |
| `lib/app/theme.dart` | `AppTheme.getLightTheme()`, `AppTheme.getDarkTheme()` |
| `lib/core/constants/app_colors.dart` | `AppColors` (primary, income, expense, transfer, success, error, background, surface, categoryColors) |
| `lib/core/constants/app_strings.dart` | `AppStrings` — semua string UI Bahasa Indonesia |
| `lib/core/constants/supabase_keys.dart` | `SupabaseKeys.supabaseUrl`, `SupabaseKeys.supabaseAnonKey` |
| `lib/core/utils/currency_formatter.dart` | `CurrencyFormatter.format()`, `.parse()`, `.formatCompact()` |
| `lib/core/utils/date_formatter.dart` | `DateFormatter.formatLongDate()`, `.formatShortDate()`, `.formatMonthYear()`, `.relative()` |
| `lib/core/utils/validators.dart` | `Validators.validateEmail/Password/Amount/Name/Required/Notes/...` |

---

## FILE MAP — Data Layer

| File | Class / Konten |
|---|---|
| `lib/data/models/models.dart` | Barrel: `UserModel`, `CashbookModel`, `WalletModel`, `CategoryModel`, `TransactionModel`, `TransferModel` |
| `lib/data/repositories/cashbook_wallet_repository.dart` | `CashbookRepository`, `WalletRepository`, `TransactionRepository` |

**Setiap model** punya: `fromJson()`, `toJson()`, `toEntity()`

---

## FILE MAP — Domain Layer

| File | Class / Konten |
|---|---|
| `lib/domain/entities/entities.dart` | `UserEntity`, `CashbookEntity`, `WalletEntity`, `CategoryEntity`, `TransactionEntity`, `TransferEntity`, `RecurringTransactionEntity` |
| `lib/domain/entities/entities.dart` | Enum: `WalletType` (cash/bankAcc/eWallet), `TransactionType` (income/expense), `RecurringFrequency` |
| `lib/domain/usecases/` | **KOSONG** — belum diimplementasi |

---

## FILE MAP — Presentation Layer

### Providers
| File | Provider | Type | Catatan |
|---|---|---|---|
| `lib/presentation/providers/providers.dart` | `supabaseClientProvider` | `Provider` | DI untuk Supabase client |
| `lib/presentation/providers/providers.dart` | `cashbookRepositoryProvider`, `walletRepositoryProvider`, `transactionRepositoryProvider` | `Provider` | DI untuk semua repository |
| `lib/presentation/providers/providers.dart` | `authStateProvider` | `StreamProvider` | Listen auth state changes |
| `lib/presentation/providers/providers.dart` | `currentUserProvider` | `FutureProvider` | Current logged-in user |
| `lib/presentation/providers/providers.dart` | `setupInProgressProvider` | `StateProvider<bool>` | ⚡ Flag untuk suppress router redirect saat onboarding |
| `lib/presentation/providers/providers.dart` | `activeCashbookProvider` | `StateProvider` | Cashbook yg sdg dipilih (set otomatis oleh defaultCashbookProvider) |
| `lib/presentation/providers/providers.dart` | `cashbooksProvider` | `FutureProvider` | Daftar semua cashbook user |
| `lib/presentation/providers/providers.dart` | `defaultCashbookProvider` | `FutureProvider` | ⚡ Auto-load default cashbook & set ke active |
| `lib/presentation/providers/providers.dart` | `walletsProvider` | `FutureProvider` | Dompet di active cashbook |
| `lib/presentation/providers/providers.dart` | `totalBalanceProvider` | `FutureProvider` | Total saldo semua dompet |
| `lib/presentation/providers/providers.dart` | `categoriesProvider` | `FutureProvider.family` | By cashbookId |
| `lib/presentation/providers/providers.dart` | `transactionFilterProvider` | `StateProvider` | Filter (tipe, bulan) |
| `lib/presentation/providers/providers.dart` | `transactionsProvider` | `FutureProvider` | Transaksi dengan filter |
| `lib/presentation/providers/providers.dart` | `selectedMonthProvider` | `StateProvider<DateTime>` | Bulan yg dipilih di transaction list |
| `lib/presentation/providers/providers.dart` | `monthlySummaryProvider` | `FutureProvider` | Summary income/expense setiap bulan |
| `lib/presentation/providers/providers.dart` | `transfersProvider` | `FutureProvider` | Transfer history |
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
| `lib/presentation/screens/dashboard/dashboard_screen.dart` | `DashboardScreen`, `_CashbookSwitcher`, `_TotalBalanceCard`, `_MonthlySection`, `_WalletSection`, `_TutorialOverlay`, `_TutorialCard`, `_StepDot` | ✅ |
| `lib/presentation/screens/splash/loading_screen.dart` | `LoadingScreen` — pre-warm providers sebelum masuk Dashboard | ✅ |
| `lib/presentation/screens/wallet/wallet_list_screen.dart` | `WalletListScreen`, `WalletListItem` | ✅ |
| `lib/presentation/screens/wallet/wallet_form_screen.dart` | `WalletFormScreen` | ✅ |
| `lib/presentation/screens/wallet/wallet_detail_screen.dart` | `WalletDetailScreen`, `_walletMonthlySummaryProvider`, `_walletTransactionsProvider` | ✅ |
| `lib/presentation/screens/transaction/transaction_list_screen.dart` | `TransactionListScreen`, `_FilterBar`, `_TypeChip`, `_SummaryBar`, `_DateHeader`, `_MonthPickerDialog` | ✅ |
| `lib/presentation/screens/transaction/transaction_form_screen.dart` | `TransactionFormScreen`, `_AmountField`, `_CategoryPickerSheet` | ✅ |
| `lib/presentation/screens/transaction/transaction_detail_screen.dart` | `TransactionDetailScreen`, `_DetailRow` | ✅ |
| `lib/presentation/screens/transfer/transfer_screen.dart` | `TransferScreen`, `_WalletDropdownItem`, `_ThousandSeparatorFormatter` | ✅ |
| `lib/presentation/screens/report/monthly_report_screen.dart` | `MonthlyReportScreen`, `_MonthPicker`, `_MonthYearPickerDialog`, `_SummarySection`, `_SummaryCard`, `_NetCard`, `_PieChartSection`, `_TypeToggle`, `_CategoryLegend`, `_BarChartSection`, `_LegendDot` | ✅ |
| `lib/presentation/screens/settings/` | *(kosong)* | ⏳ |

### Widgets
| File | Class | Catatan |
|---|---|---|
| `lib/presentation/widgets/transaction_tile.dart` | `TransactionTile` (props: transaction, onTap, showWalletName) | **💚 Left accent bar by type** — `Container(width:4, color:typeColor)` sebagai child pertama di Row + `clipBehavior: Clip.antiAlias` + `IntrinsicHeight`. ⚠️ JANGAN gunakan `Border()` dengan sisi berbeda lebar + `borderRadius` → menyebabkan clip bug (konten hilang) |

---

## ROUTE TABLE

| Konstanta `AppRoutes` | Path | Screen | Catatan |
|---|---|---|---|
| `AppRoutes.splash` | `/splash` | `_SplashScreen` | Loading spinner, inisialisasi auth |
| `AppRoutes.landing` | `/landing` | `LandingScreen` | Entry publik (belum login), fade+slide anim |
| `AppRoutes.login` | `/login` | `LoginScreen` | Back button → `/landing` |
| `AppRoutes.register` | `/register` | `RegisterScreen` | Back button → `/landing` |
| `AppRoutes.dashboard` | `/dashboard` | `DashboardScreen` | Protected route |
| `AppRoutes.cashbooks` | `/cashbooks` | `CashbookListScreen` | |
| `AppRoutes.cashbookForm` | `/cashbooks/form` | `CashbookFormScreen` | |
| `AppRoutes.wallets` | `/wallets` | `WalletListScreen` | |
| `AppRoutes.walletForm` | `/wallets/form` | `WalletFormScreen` | |
| `AppRoutes.walletDetail` | `/wallets/detail` | `WalletDetailScreen` | |
| `AppRoutes.transactions` | `/transactions` | `TransactionListScreen` | |
| `AppRoutes.transactionForm` | `/transactions/form` | `TransactionFormScreen` | |
| `AppRoutes.transactionDetail` | `/transactions/detail` | `TransactionDetailScreen` | |
| `AppRoutes.transfer` | `/transfer` | `TransferScreen` | Transfer antar dompet + riwayat |
| `AppRoutes.monthlyReport` | `/report/monthly` | `MonthlyReportScreen` | Month picker, summary cards, pie chart, bar chart |
| `AppRoutes.settings` | `/settings` | *(belum ada GoRoute handler)* | |

**Navigasi:** `context.go(AppRoutes.xxx)` atau `context.push(AppRoutes.xxx, extra: entity)`

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
| **Dashboard + Transaction List** | **✅ Lengkap** | Total balance, monthly summary, wallet carousel, add transaction FAB, filter by type/month |
| Cashbook CRUD | ✅ Lengkap | |
| Wallet CRUD + Detail | ✅ Lengkap | |
| Transaksi CRUD + Detail | ✅ Lengkap | |
| Transfer antar wallet | ✅ Lengkap | Screen transfer, route, repository method, provider refresh sudah terpasang |
| Laporan / Report | ✅ P0-P2 | Month picker, summary cards, pie chart (kategori), bar chart (tren 12 bulan) |
| Settings | ⏳ Belum | Route ada, folder screen kosong |
| Recurring Transactions | ⏳ Belum | Entity ada, tidak ada repo/screen |
| Local DB (Drift) | ⏳ Belum | Dependency ada, belum digunakan |

---

## PROVIDER DEPENDENCIES — Diagram

```
┌─ Tier 1: Core DI
│  ├─ supabaseClientProvider
│  ├─ cashbookRepositoryProvider
│  ├─ walletRepositoryProvider
│  └─ transactionRepositoryProvider
│
├─ Tier 2: Auth
│  ├─ authStateProvider
│  └─ currentUserProvider
│
├─ Tier 3: Setup & State
│  ├─ setupInProgressProvider (StateProvider - suppress redirect)
│  ├─ activeCashbookProvider (StateProvider - manual set or auto by defaultCashbookProvider)
│  └─ defaultCashbookProvider ← WATCHES: currentUserProvider, cashbookRepositoryProvider
│                              ← AUTO-SETS: activeCashbookProvider
│
└─ Tier 4: Data (depends on activeCashbookProvider)
   ├─ cashbooksProvider
   ├─ walletsProvider ← WATCHES: activeCashbookProvider
   ├─ categoriesProvider ← by cashbookId
   ├─ transactionsProvider ← WATCHES: transactionFilterProvider
   ├─ monthlySummaryProvider
   ├─ totalBalanceProvider ← sums walletsProvider
   └─ transfersProvider
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
ref.invalidate(categoriesProvider);           // jika ada perubahan kategori
```

**Providers yang perlu di-invalidate setelah mutasi transaksi:**
`transactionsProvider`, `walletsProvider`, `totalBalanceProvider`, `monthlySummaryProvider`

---

## CATEGORY ICONS (string → IconData di TransactionTile)

`makanan`, `transportasi`, `belanja`, `tagihan`, `hiburan`, `kesehatan`, `pendidikan`, `gaji`, `bisnis`, `investasi`, `transfer`, `lainnya`

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

### ⏳ Sprint 4 — Polish & Advanced
- [x] Transfer between wallets
- [ ] Data export (CSV, PDF)
- [ ] Dark mode
- [ ] Local cache (Drift)
- [ ] Notification reminders
- [ ] Cashbook switcher UI improvements
- [ ] Update PROJECT_DICTIONARY after completion

---

