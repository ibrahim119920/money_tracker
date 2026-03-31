# Feature Modules — Money Tracker

## 1. Authentication

**Status:** ✅ Complete

### Files Involved
- `lib/presentation/screens/auth/landing_screen.dart`
- `lib/presentation/screens/auth/login_screen.dart`
- `lib/presentation/screens/auth/register_screen.dart`

### UI Entry Points
- App start → `/splash` → `/landing` (unauthenticated)
- `/login` — email/password sign-in
- `/register` — multi-step sign-up

### Business Logic
- Auth handled directly by `supabase_flutter` — no repository wrapper
- `authStateProvider` (StreamProvider) listens to `Supabase.instance.client.auth.onAuthStateChange`
- After sign-in/sign-up: `context.go(AppRoutes.loading)` — navigasi ke `LoadingScreen` untuk pre-warm data
- After sign-up: jika session null (email verification pending), navigate ke landing dengan info message
- Error detection: string pattern matching on Supabase error messages

### First-Time Onboarding
- Terjadi di **Dashboard** via `_TutorialOverlay`, bukan di register screen
- Step 1: jika `cashbooksProvider` kosong → push ke `/cashbooks/form`
- Step 2: jika `walletsProvider` kosong → push ke `/wallets/form`
- Overlay reaktif: menghilang otomatis setelah kedua provider terisi

---

## 2. Dashboard

**Status:** ✅ Complete

### Files Involved
- `lib/presentation/screens/dashboard/dashboard_screen.dart`
- `lib/presentation/screens/splash/loading_screen.dart`

### UI Components
- `_CashbookSwitcher` — dropdown/chip to change active cashbook
- `_TotalBalanceCard` — sum of all wallet balances
- `_MonthlySection` — income vs expense for current month
- `_WalletSection` — horizontal scrollable wallet cards with balances
- `_TutorialOverlay` — fullscreen mandatory onboarding (muncul jika belum ada cashbook/wallet)
- `_TutorialCard` — card guide per step
- `_StepDot` — step indicator

### Business Logic
- `LoadingScreen` pre-warms `defaultCashbookProvider`, `cashbooksProvider`, `walletsProvider` sebelum masuk Dashboard
- Navigasi ke Dashboard hanya setelah ketiganya resolve (mencegah race condition `walletsProvider` return `[]` sebelum `activeCashbookProvider` ter-set)
- `defaultCashbookProvider` menggunakan `getEarliestCashbook()` (order `created_at ASC`) untuk auto-load
- `totalBalanceProvider` sums all `current_balance` values from `walletsProvider`
- `monthlySummaryProvider` queries transactions grouped by type for the current month
- `_TutorialOverlay` tidak tampil selama provider masih loading (hardened race condition guard)

### Data Layer
- `CashbookRepository.getEarliestCashbook(userId)` — order `created_at ASC`, `maybeSingle`
- `WalletRepository.getWalletsByCashbook(cashbookId)` — returns all active wallets

---

## 3. Cashbook Management

**Status:** ✅ Complete

### Files Involved
- `lib/presentation/screens/cashbook/cashbook_list_screen.dart` — `CashbookListScreen`, `CashbookListItem`
- `lib/presentation/screens/cashbook/cashbook_form_screen.dart` — `CashbookFormScreen`

### UI Entry Points
- Route: `/cashbooks` (list), `/cashbooks/form` (create/edit)
- Accessed from dashboard `_CashbookSwitcher`

### Business Logic
- Creating a cashbook with `setAsDefault: true` auto-sets it as the active cashbook
- `activeCashbookProvider` is a `StateProvider`; switching cashbook updates all downstream providers
- Soft delete: sets `is_deleted = true`

### Data Layer
- `CashbookRepository.createCashbook()` — supports `setAsDefault` parameter
- `CashbookRepository.getUserCashbooks(userId)` — excludes `is_deleted`
- `CashbookRepository.getEarliestCashbook(userId)` — order `created_at ASC` (digunakan untuk auto-load)
- `CashbookRepository.getDefaultCashbook(userId)` — filters `is_default = true` (masih ada, tidak dipakai auto-load)

---

## 4. Wallet Management

**Status:** ✅ Complete

### Files Involved
- `lib/presentation/screens/wallet/wallet_list_screen.dart`
- `lib/presentation/screens/wallet/wallet_form_screen.dart`
- `lib/presentation/screens/wallet/wallet_detail_screen.dart`

### UI Entry Points
- Route: `/wallets` (list), `/wallets/form` (create/edit), `/wallets/detail` (view)
- Wallet detail passed via `state.extra as WalletEntity`

### UI Components (wallet_detail_screen.dart)
- `_walletMonthlySummaryProvider` — local FutureProvider.family for per-wallet monthly summary
- `_walletTransactionsProvider` — local FutureProvider.family for per-wallet transaction list

### Business Logic
- Wallet types: `cash`, `bankAcc`, `eWallet` (from `WalletType` enum)
- `current_balance` is auto-updated by Supabase triggers on transaction insert/delete
- `sort_order` field controls display order

### Data Layer
- `WalletRepository` in `cashbook_wallet_repository.dart`

---

## 5. Transaction Management

**Status:** ✅ Complete

### Files Involved
- `lib/presentation/screens/transaction/transaction_list_screen.dart`
- `lib/presentation/screens/transaction/transaction_form_screen.dart`
- `lib/presentation/screens/transaction/transaction_detail_screen.dart`
- `lib/presentation/widgets/transaction_tile.dart`

### UI Entry Points
- Route: `/transactions` (list), `/transactions/form` (create/edit), `/transactions/detail` (view)
- Form receives `extra: {'type': TransactionType, 'transaction': TransactionEntity?}`
- Detail receives `extra: TransactionEntity`

### UI Components (transaction_list_screen.dart)
- `_FilterBar` — type chips (Income / Expense / All)
- `_TypeChip` — individual filter chip
- `_SummaryBar` — total income and expense for selected month
- `_DateHeader` — grouped date separator
- `_MonthPickerDialog` — month/year selection wheel

### Business Logic
- `transactionFilterProvider` (`StateProvider`) holds current `type` filter and `month`
- `selectedMonthProvider` (`StateProvider<DateTime>`) drives month display
- `transactionsProvider` reads both filter providers and queries accordingly
- After any mutation: must invalidate `transactionsProvider`, `walletsProvider`, `totalBalanceProvider`, `monthlySummaryProvider`

### Data Layer
- `TransactionRepository.createTransaction()` — inserts and returns entity
- `TransactionRepository.updateTransaction()` — updates, recalculates wallet balance
- `TransactionRepository.deleteTransaction()` — soft delete: `is_deleted = true`
- `TransactionRepository.getMonthlySummary(cashbookId, month)` — returns income/expense totals

---

## 6. Categories

**Status:** ✅ Integrated (no standalone screen — picker only)

### Files Involved
- `_CategoryPickerSheet` inside `transaction_form_screen.dart`
- `categoriesProvider` in `providers.dart`

### Business Logic
- Categories have `cashbook_id` (user-specific) or null (system-wide)
- `is_system = true` categories ship as Supabase seed data (cannot be deleted)
- Icons: string keys (`makanan`, `transportasi`, `gaji`, etc.) mapped to `IconData` at render time

---

## 7. Transfer Between Wallets

**Status:** ✅ Complete

### Files Involved
- `lib/presentation/screens/transfer/transfer_screen.dart`
- `lib/data/repositories/cashbook_wallet_repository.dart` (`TransactionRepository.createTransfer`, `getTransfersByCashbook`)
- `lib/presentation/providers/providers.dart` (`transfersProvider`)
- `lib/app/router.dart` (GoRoute `/transfer`)
- `lib/presentation/screens/dashboard/dashboard_screen.dart` (action sheet entry)

### UI Components
- Form transfer: dompet asal, dompet tujuan, jumlah, tanggal, catatan
- Validasi: dompet asal/tujuan tidak boleh sama, amount wajib > 0
- Riwayat transfer: list transfer dengan tanggal, catatan, dan nominal

### Business Logic
- Transfer dibuat via repository (`createTransfer`), bukan query langsung dari screen
- Cek saldo dompet asal sebelum create transfer
- Setelah create transfer: invalidate `transfersProvider`, `walletsProvider`, `totalBalanceProvider`
- Akses cepat dari Dashboard bottom sheet: opsi Transfer (aktif)

### Data Layer
- `TransactionRepository.createTransfer()` — insert transfer baru
- `TransactionRepository.getTransfersByCashbook()` — fetch daftar transfer + nama dompet asal/tujuan

---

## 8. Reports

**Status:** ✅ P0–P2 Complete (P3 pending)

### Files Involved
- `lib/presentation/screens/report/monthly_report_screen.dart`

### UI Components
- `_MonthPicker` — navigasi bulan
- `_SummarySection` + `_SummaryCard` + `_NetCard` — ringkasan pemasukan/pengeluaran/net
- `_PieChartSection` + `_TypeToggle` + `_CategoryLegend` — pie chart breakdown kategori
- `_BarChartSection` + `_LegendDot` — bar chart tren 12 bulan

### Business Logic
- `reportMonthProvider` (`StateProvider<DateTime>`) — bulan aktif di laporan
- `reportMonthlySummaryProvider` — total income/expense bulan terpilih
- `reportCategoryBreakdownProvider` — breakdown per kategori berdasarkan tipe
- `reportYearlyTrendProvider` — data 12 bulan untuk bar chart
- Route `/report/monthly` — terdaftar di router

### Yang Belum
- P3: perbandingan bulan & export PDF
- `fl_chart` dependency already in `pubspec.yaml` (ready for charts)

---

## 9. Settings

**Status:** ⏳ Not Implemented

- Route `/settings` registered in `AppRoutes`
- No GoRoute handler; `lib/presentation/screens/settings/` folder is empty
