# State Management — Money Tracker

## Solution: Riverpod 2.x (`flutter_riverpod ^2.4.0`)

All state lives in **`lib/presentation/providers/providers.dart`** — a single barrel file.

---

## Provider Tiers

### Tier 1 — Dependency Injection (Provider)

These are synchronous; they just wire up dependencies.

| Provider | Type | Returns |
|---|---|---|
| `supabaseClientProvider` | `Provider` | `SupabaseClient` from `Supabase.instance.client` |
| `sharedPreferencesProvider` | `Provider<Future<SharedPreferences>>` | Future instance dari `SharedPreferences.getInstance()` |
| `cashbookRepositoryProvider` | `Provider` | `CashbookRepository` (receives client via ref) |
| `walletRepositoryProvider` | `Provider` | `WalletRepository` |
| `transactionRepositoryProvider` | `Provider` | `TransactionRepository` |
| `settingsRepositoryProvider` | `Provider` | `SettingsRepository` |

### Tier 2 — Authentication (StreamProvider / FutureProvider)

| Provider | Type | Returns |
|---|---|---|
| `authStateProvider` | `StreamProvider<AuthState>` | Live stream from Supabase Auth |
| `currentUserProvider` | `FutureProvider<UserEntity?>` | Current user or null |

### Tier 3 — Setup & Active State (StateProvider)

| Provider | Type | Initial |
|---|---|---|
| `setupInProgressProvider` | `StateProvider<bool>` | `false` — set to `true` during onboarding wizard to suppress router redirects |
| `activeCashbookProvider` | `StateProvider<CashbookEntity?>` | `null` — auto-set by `defaultCashbookProvider` |
| `appThemeModeProvider` | `StateNotifierProvider<ThemeModeNotifier, ThemeMode>` | `ThemeMode.system` |

### Tier 3b — Sequential Add Drafts (auto-disposed controller)

| Provider | Type | Notes |
|---|---|---|
| `transactionDraftProvider` | `AutoDisposeNotifierProvider<TransactionDraftController, TransactionDraft>` | Typed income/expense draft; integer Rupiah amount, category, wallet, date, notes |
| `transferDraftProvider` | `AutoDisposeNotifierProvider<TransferDraftController, TransferDraft>` | Typed transfer draft; source/destination conflict is cleared when source changes |

The controllers contain only form state and small mutations. They do not own a `PageController`, `BuildContext`, Supabase client, or animation object; screen-local navigation and controllers remain in the screen state.

### Tier 4 — Cashbook Data (FutureProvider)

| Provider | Type | Notes |
|---|---|---|
| `defaultCashbookProvider` | `FutureProvider` | Loads default cashbook; calls `ref.read(activeCashbookProvider.notifier).state = cashbook` as side effect |
| `cashbooksProvider` | `FutureProvider<List<CashbookEntity>>` | All cashbooks for current user; delegates to `CashbookRepository.getUserCashbooks()` |

### Tier 5 — Wallet & Financial Data (FutureProvider)

| Provider | Type | Depends On |
|---|---|---|
| `walletsProvider` | `FutureProvider<List<WalletEntity>>` | `activeCashbookProvider`; delegates to `WalletRepository.getWallets()` |
| `totalBalanceProvider` | `FutureProvider<int>` | `activeCashbookProvider`; delegates to `CashbookRepository.getTotalBalance()` |
| `cashbookBalanceProvider` | `FutureProvider.family<int, String>` | Named per-cashbook balance provider for cashbook rows; avoids creating a new anonymous provider on every rebuild |
| `futureTransactionProjectionProvider` | `FutureProvider<FutureTransactionProjection>` | Active cashbook; derives today's balance and end-of-current-month projection from future income/expense using integer Rupiah |

### Tier 6 — Transaction Data (StreamProvider + Provider + StateProvider)

| Provider | Type | Notes |
|---|---|---|
| `transactionFilterProvider` | `StateProvider` | Holds `{type, month}` filter state |
| `selectedMonthProvider` | `StateProvider<DateTime>` | Selected month in transaction list |
| `transactionHistorySegmentProvider` | `StateProvider<TransactionHistorySegment>` | UI segment state for All / Income / Expense / Transfer |
| `transactionsProvider` | `StreamProvider<List<TransactionEntity>>` | Reads the transaction filter and `selectedMonthProvider` |
| `transactionListItemsProvider` | `Provider<AsyncValue<List<TransactionListItem>>>` | Transforms the transaction stream into grouped UI rows outside `TransactionListScreen.build()` |
| `transactionDetailProvider` | `FutureProvider.family<TransactionEntity, String>` | Fetches fresh transaction detail by `transactionId` (with wallet/category joins) |
| `monthlySummaryProvider` | `FutureProvider<Map>` | Income/expense totals for selected month; delegates to `TransactionRepository.getMonthlySummaryForReport()` |
| `categoriesProvider` | `FutureProvider.family` | Keyed by `cashbookId` |
| `transfersProvider` | `FutureProvider<List<TransferEntity>>` | Transfer history; delegates to `TransactionRepository.getTransfersByCashbook()` |
| `selectedMonthTransfersProvider` | `FutureProvider<List<TransferEntity>>` | Active cashbook transfers restricted to `selectedMonthProvider` for the fourth history segment |

---

## State Flow

```
User taps "Add Income" or "Add Expense"
  ↓
TransactionAddFlowScreen opens at `/transactions/add/income` or `/transactions/add/expense`
  ↓
User completes amount → category → wallet → date → optional notes
  ↓
`_submit()` re-reads category/wallet data, then calls the existing repository:
  1. repo.createTransaction(...) — await Supabase insert
  2. ref.invalidate(transactionsProvider)    ← list refresh
  3. ref.invalidate(walletsProvider)         ← balance update
  4. ref.invalidate(totalBalanceProvider)    ← dashboard refresh
  5. ref.invalidate(monthlySummaryProvider)  ← summary recalc
  6. ref.invalidate(futureTransactionProjectionProvider)
  7. ref.invalidate(cashbookBalanceProvider(cashbookId))
  8. context.pop()
  ↓
Riverpod rebuilds all watching widgets automatically
```

Income and expense can be scheduled in the future, while transfer still rejects future calendar dates in the draft and repository. Transfer uses the same controlled five-step shell with `TransferDraft`, and submits through `createTransfer()` with invalidation of `transfersProvider`, `selectedMonthTransfersProvider`, `walletsProvider`, and `totalBalanceProvider`. Transfer history is a separate `/transfer/history` route.

---

## How UI Subscribes

Every screen extends `ConsumerWidget` or `ConsumerStatefulWidget`.

```dart
// Reading async data (FutureProvider)
final walletsAsync = ref.watch(walletsProvider);
walletsAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
  data: (wallets) => WalletList(wallets),
);

// Reading simple state (StateProvider)
final activeMonth = ref.watch(selectedMonthProvider);

// Writing state
ref.read(selectedMonthProvider.notifier).state = newMonth;

// Triggering refresh after mutation
ref.invalidate(transactionsProvider);
```

---

## Mutation Pattern

All write operations follow this pattern:

1. Read the repository: `final repo = ref.read(xxxRepositoryProvider)`
2. Await the async operation inside a `try/catch`
3. On success: `ref.invalidate(...)` all affected providers
4. On success: navigate (`context.pop()` or `context.go(...)`)
5. On error: show `SnackBar` with `AppColors.error` background

**Never** call `ref.invalidate()` before the operation succeeds.

---

## Special Patterns

### defaultCashbookProvider Side Effect
This provider does double duty: it fetches the default cashbook AND writes it into `activeCashbookProvider`. All downstream data providers depend on `activeCashbookProvider`, so `DashboardScreen` must watch `defaultCashbookProvider` in its build method to trigger the chain.

### Repository-Backed Providers
Some providers no longer talk to Supabase directly. `cashbooksProvider`, `walletsProvider`, `totalBalanceProvider`, `cashbookBalanceProvider`, `futureTransactionProjectionProvider`, `monthlySummaryProvider`, `categoriesProvider`, and the transfer providers delegate to repository methods so the provider layer stays focused on orchestration, state derivation, and invalidation.

### Loading Pipeline Split
`LoadingScreen` resolves `defaultCashbookProvider`, `cashbooksProvider`, and `walletsProvider` before entering the dashboard. The readiness check now lives outside `build()` so the pre-warm flow stays stable across rebuilds.

### setupInProgressProvider
Set to `true` before launching the first-time setup wizard in `RegisterScreen`. Prevents the router's `redirect` function from navigating away mid-wizard. Must be set back to `false` when wizard completes (even on error).

### appThemeModeProvider
Used by `MoneyTrackerApp` in `main.dart` as `themeMode` source. `SettingsScreen` updates this provider directly for Sistem/Terang/Gelap switching. `ThemeModeNotifier` reads `sharedPreferencesProvider` and persists the selected mode.

### categoriesProvider.family
Uses `.family` modifier keyed by `cashbookId`. Categories are per cashbook (user-defined) plus system-wide ones (null cashbook_id). Pass the active cashbook ID when watching: `ref.watch(categoriesProvider(cashbookId))`.
The shared picker creates user categories through `TransactionRepository.createCategory()` and invalidates this exact family key before selecting the returned persisted entity.

### transactionListItemsProvider
This provider derives from `transactionsProvider` and precomputes the header/item rows once per data refresh. `TransactionListScreen` consumes these rows directly so grouping work does not happen inside the widget build.

---

## What to Invalidate After Each Mutation

| Operation | Invalidate |
|---|---|
| Create/update/delete transaction | `transactionsProvider`, `walletsProvider`, `totalBalanceProvider`, `monthlySummaryProvider`, `futureTransactionProjectionProvider`, `cashbookBalanceProvider(cashbookId)` |
| Create category | `categoriesProvider(cashbookId)` |
| Create/update/delete wallet | `walletsProvider`, `totalBalanceProvider`, `futureTransactionProjectionProvider`, `cashbookBalanceProvider(cashbookId)` |
| Create/update/delete cashbook | `cashbooksProvider`, `defaultCashbookProvider` |
| Create transfer | `transfersProvider`, `selectedMonthTransfersProvider`, `walletsProvider`, `totalBalanceProvider` |
