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
| `cashbookRepositoryProvider` | `Provider` | `CashbookRepository` (receives client via ref) |
| `walletRepositoryProvider` | `Provider` | `WalletRepository` |
| `transactionRepositoryProvider` | `Provider` | `TransactionRepository` |

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

### Tier 4 — Cashbook Data (FutureProvider)

| Provider | Type | Notes |
|---|---|---|
| `defaultCashbookProvider` | `FutureProvider` | Loads default cashbook; calls `ref.read(activeCashbookProvider.notifier).state = cashbook` as side effect |
| `cashbooksProvider` | `FutureProvider<List<CashbookEntity>>` | All cashbooks for current user |

### Tier 5 — Wallet & Financial Data (FutureProvider)

| Provider | Type | Depends On |
|---|---|---|
| `walletsProvider` | `FutureProvider<List<WalletEntity>>` | `activeCashbookProvider` |
| `totalBalanceProvider` | `FutureProvider<int>` | `walletsProvider` (sums `current_balance`) |

### Tier 6 — Transaction Data (FutureProvider + StateProvider)

| Provider | Type | Notes |
|---|---|---|
| `transactionFilterProvider` | `StateProvider` | Holds `{type, month}` filter state |
| `selectedMonthProvider` | `StateProvider<DateTime>` | Selected month in transaction list |
| `transactionsProvider` | `FutureProvider<List<TransactionEntity>>` | Reads both filter providers |
| `monthlySummaryProvider` | `FutureProvider<Map>` | Income/expense totals for selected month |
| `categoriesProvider` | `FutureProvider.family` | Keyed by `cashbookId` |
| `transfersProvider` | `FutureProvider<List<TransferEntity>>` | Transfer history |

---

## State Flow

```
User taps "Add Transaction"
  ↓
TransactionFormScreen opens
  ↓
User fills form, taps Save
  ↓
_createTransaction() in screen state:
  1. repo.createTransaction(...) — await Supabase insert
  2. ref.invalidate(transactionsProvider)    ← list refresh
  3. ref.invalidate(walletsProvider)         ← balance update
  4. ref.invalidate(totalBalanceProvider)    ← dashboard refresh
  5. ref.invalidate(monthlySummaryProvider)  ← summary recalc
  6. context.pop()
  ↓
Riverpod rebuilds all watching widgets automatically
```

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

### setupInProgressProvider
Set to `true` before launching the first-time setup wizard in `RegisterScreen`. Prevents the router's `redirect` function from navigating away mid-wizard. Must be set back to `false` when wizard completes (even on error).

### categoriesProvider.family
Uses `.family` modifier keyed by `cashbookId`. Categories are per cashbook (user-defined) plus system-wide ones (null cashbook_id). Pass the active cashbook ID when watching: `ref.watch(categoriesProvider(cashbookId))`.

---

## What to Invalidate After Each Mutation

| Operation | Invalidate |
|---|---|
| Create/update/delete transaction | `transactionsProvider`, `walletsProvider`, `totalBalanceProvider`, `monthlySummaryProvider` |
| Create/update/delete wallet | `walletsProvider`, `totalBalanceProvider` |
| Create/update/delete cashbook | `cashbooksProvider`, `defaultCashbookProvider` |
| Create transfer | `transfersProvider`, `walletsProvider`, `totalBalanceProvider` |
