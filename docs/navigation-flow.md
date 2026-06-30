# Navigation Flow — Money Tracker

## Solution: GoRouter 13.x (`go_router ^13.2.0`)

Router configured in `lib/app/router.dart` via `goRouterProvider`.

---

## Route Table

| Constant | Path | Screen / Builder | Auth Required |
|---|---|---|
---|
| `AppRoutes.splash` | `/splash` | `_SplashScreen` (auth init spinner) | No |
| `AppRoutes.loading` | `/loading` | `LoadingScreen` (data pre-warm) | ✅ Yes |
| `AppRoutes.landing` | `/landing` | `LandingScreen` | No |
| `AppRoutes.login` | `/login` | `LoginScreen` | No |
| `AppRoutes.register` | `/register` | `RegisterScreen` | No |
| `AppRoutes.dashboard` | `/dashboard` | `DashboardScreen` | ✅ Yes |
| `AppRoutes.cashbooks` | `/cashbooks` | `CashbookListScreen` | ✅ Yes |
| `/cashbooks/form` | `/cashbooks/form` | `CashbookFormScreen(cashbook?)` | ✅ Yes |
| `AppRoutes.wallets` | `/wallets` | `WalletListScreen` | ✅ Yes |
| `/wallets/form` | `/wallets/form` | `WalletFormScreen(wallet?)` | ✅ Yes |
| `/wallets/detail` | `/wallets/detail` | `WalletDetailScreen(wallet)` | ✅ Yes |
| `AppRoutes.transactions` | `/transactions` | `TransactionListScreen` | ✅ Yes |
| `/transactions/form` | `/transactions/form` | `TransactionFormScreen(type, transaction?)` | ✅ Yes |
| `/transactions/detail` | `/transactions/detail` | `TransactionDetailScreen(transaction)` | ✅ Yes |
| `AppRoutes.transfer` | `/transfer` | `TransferScreen` | ✅ Yes |
| `AppRoutes.monthlyReport` | `/report/monthly` | `MonthlyReportScreen` | ✅ Yes |
| `AppRoutes.settings` | `/settings` | `SettingsScreen` | ✅ Yes |

---

## Screen Hierarchy

```
/splash  ──────────────────────────────────────────────
  │ (auth resolved)
  ├── logged out → /landing
  │     ├── /login
  │     └── /register
  │
  └── logged in → /loading  (pre-warm providers)
        │ (defaultCashbookProvider + cashbooksProvider + walletsProvider resolved)
        └── /dashboard
              ├── _TutorialOverlay (fullscreen, jika belum ada cashbook/wallet)
              │     ├── step 1 → /cashbooks/form  (buat cashbook pertama)
              │     └── step 2 → /wallets/form    (buat dompet pertama)
              ├── /cashbooks
              │     └── /cashbooks/form     (create or edit cashbook)
              ├── /wallets
              │     ├── /wallets/form       (create or edit wallet)
              │     └── /wallets/detail     (wallet detail + transactions)
              ├── /transactions
              │     ├── /transactions/form  (create or edit transaction)
              │     └── /transactions/detail
              ├── /transfer          ✅ implemented
              ├── /report/monthly    ✅ implemented
              └── /settings          ✅ implemented
```

---

## Auth Redirect Logic

Implemented in the `redirect` callback of `goRouterProvider`:

```
Request any route
  │
  ├── authStateProvider is loading?
  │     YES → redirect to /splash
  │
  ├── Current path is /splash?
  │     YES + logged in  → /loading
  │     YES + logged out → /landing
  │
  ├── Current path is /loading?
  │     YES + logged out → /landing
  │
  ├── Logged in + on public route (/landing, /login, /register)?
  │     YES → /loading
  │
  └── Logged out + on /dashboard?
        YES → /landing
```

`_RouterNotifier` listens to `authStateProvider` and calls `notifyListeners()` whenever auth state changes, which triggers GoRouter to re-evaluate the redirect.

---

## Navigation Patterns

### Declarative navigation (replaces stack)
```dart
context.go(AppRoutes.dashboard);
```

### Push onto stack (preserves back button)
```dart
context.push(AppRoutes.transactions);
```

### Passing data (no typed routes)
```dart
// Passing a single entity
context.push('/wallets/detail', extra: walletEntity);

// Passing multiple values
context.push('/transactions/form', extra: {
  'type': TransactionType.expense,
  'transaction': null,  // null = create mode
});
```

### Reading extra in router builder
```dart
builder: (context, state) => WalletDetailScreen(
  wallet: state.extra as WalletEntity,
),
```

---

## Entry Points Summary

| Scenario | Entry Screen | Notes |
|---|---|---|
| Cold start | `/splash` | Always; router resolves auth then redirects |
| Not logged in | `/landing` | CTA buttons → `/login` or `/register` |
| Returning user | `/loading` → `/dashboard` | Pre-warms providers; dashboard muncul dengan data siap |
| New user (post-register) | `/loading` → `/dashboard` | `_TutorialOverlay` muncul di dashboard, guided step-by-step |

---

## Known Navigation Gaps

- `/report/annual` — route terdaftar di `AppRoutes` constants; belum ada GoRoute atau screen
