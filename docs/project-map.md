# Project Map — Money Tracker

## Root Files

| File | Purpose |
|---|---|
| `pubspec.yaml` | Flutter dependencies; key packages: flutter_riverpod, go_router, supabase_flutter, drift, intl, fl_chart |
| `lib/main.dart` | App entry point; locale init, Supabase init, ProviderScope, MaterialApp.router |
| `lib/core/constants/app_colors.dart` | `AppColors` — primary dark teal, lavender/lime accents, soft mint/peach neutrals, semantic status colors |
| `AGENTS.md` | AI agent entry point — start here for orientation |

---

## `lib/app/` — App Shell

| File | Contents |
|---|---|
| `router.dart` | `AppRoutes` constants, `goRouterProvider` (GoRouter + auth redirect logic), `_RouterNotifier`, `_SplashScreen` |
| `theme.dart` | `AppTheme.getLightTheme()`, `AppTheme.getDarkTheme()` — Material 3 theming |

---

## `lib/core/` — Shared Utilities (no external deps)

```
core/
├── constants/
│   ├── app_colors.dart       AppColors — primary dark teal, lavender/lime accents, mint/peach neutrals, income, expense, transfer, category palette
│   ├── app_strings.dart      AppStrings — all Indonesian UI text
│   ├── supabase_keys.dart    SupabaseKeys.supabaseUrl / .supabaseAnonKey
│   └── constants.dart        barrel re-export
└── utils/
    ├── currency_formatter.dart   CurrencyFormatter.format() / .parse() / .formatCompact()
    ├── date_formatter.dart       DateFormatter.formatLongDate() / .relative() / etc.
    ├── validators.dart           Validators.validateEmail/Password/Amount/Name/Notes/...
    └── utils.dart                barrel re-export
```

---

## `lib/domain/` — Business Logic Contracts

```
domain/
├── entities/
│   └── entities.dart   All entity classes + enums (single file)
│       Entities: UserEntity, CashbookEntity, WalletEntity,
│                 CategoryEntity, TransactionEntity, TransferEntity,
│                 RecurringTransactionEntity
│       Enums:    WalletType (cash/bankAcc/eWallet)
│                 TransactionType (income/expense)
│                 RecurringFrequency
└── usecases/           ⏳ Empty — placeholder for future use-case layer
```

---

## `lib/data/` — Data Access

```
data/
├── models/
│   └── models.dart     All JSON ↔ Entity models (single barrel file)
│       UserModel, CashbookModel, WalletModel,
│       CategoryModel, TransactionModel, TransferModel
│       Each model: fromJson() / toJson() / toEntity()
└── repositories/
    └── cashbook_wallet_repository.dart
        CashbookRepository  — cashbooks CRUD + getDefault / getUserCashbooks
        WalletRepository    — wallets CRUD + balance queries
        TransactionRepository — transactions + categories + monthly summary
```

---

## `lib/presentation/` — UI Layer

### Providers (`lib/presentation/providers/providers.dart`)
Single barrel file. See [state-management.md](state-management.md) for full provider map.

### Screens

```
screens/
├── auth/
│   ├── landing_screen.dart      LandingScreen — public entry, fade+slide animation
│   ├── login_screen.dart        LoginScreen — email/password sign-in
│   └── register_screen.dart     RegisterScreen — sign-up + first-time setup wizard
├── splash/
│   └── loading_screen.dart      LoadingScreen — pre-warm providers before dashboard
├── dashboard/
│   └── dashboard_screen.dart    DashboardScreen — balance overview, month summary, wallet list
├── cashbook/
│   ├── cashbook_list_screen.dart
│   └── cashbook_form_screen.dart
├── wallet/
│   ├── wallet_list_screen.dart
│   ├── wallet_form_screen.dart
│   └── wallet_detail_screen.dart
├── transaction/
│   ├── transaction_list_screen.dart   Filter by type + month; grouped by date via derived provider
│   ├── transaction_form_screen.dart   Create/edit income or expense
│   └── transaction_detail_screen.dart
├── transfer/
│   └── transfer_screen.dart           Create transfer + transfer history
├── report/
│   └── monthly_report_screen.dart     Monthly report with summary + charts
└── settings/
    └── settings_screen.dart           Settings P0: profile, password, theme, default cashbook, about, logout
```

### Widgets (`lib/presentation/widgets/`)

| File | Widget | Notes |
|---|---|---|
| `transaction_tile.dart` | `TransactionTile` | Left border color by type (green/red); props: transaction, onTap, showWalletName |

---

## Supabase Database Tables

| Table | PK | Key Columns |
|---|---|---|
| `users` | `user_id` | `email`, `display_name`, `is_active` |
| `cashbooks` | `cashbook_id` | `user_id`, `cashbook_name`, `is_default`, `is_deleted` |
| `wallets` | `wallet_id` | `cashbook_id`, `type`, `wallet_name`, `current_balance` (BIGINT), `is_active` |
| `categories` | `category_id` | `cashbook_id` (nullable for system), `type`, `icon`, `color`, `is_system` |
| `transactions` | `transaction_id` | `cashbook_id`, `wallet_id`, `category_id`, `type`, `amount` (BIGINT), `is_deleted` |
| `transfers` | `transfer_id` | `cashbook_id`, `from_wallet_id`, `to_wallet_id`, `amount` (BIGINT) |

---

## Feature Location Quick Reference

| Feature | Screen | Provider(s) | Repository |
|---|---|---|---|
| Auth | `screens/auth/` | `authStateProvider`, `currentUserProvider` | Supabase Auth (direct) |
| Loading / prewarm | `screens/splash/loading_screen.dart` | `defaultCashbookProvider`, `cashbooksProvider`, `walletsProvider` | CashbookRepository, WalletRepository |
| Dashboard | `screens/dashboard/` | `defaultCashbookProvider`, `totalBalanceProvider`, `monthlySummaryProvider`, `walletsProvider` | CashbookRepository, WalletRepository |
| Cashbooks | `screens/cashbook/` | `cashbooksProvider`, `activeCashbookProvider` | CashbookRepository |
| Wallets | `screens/wallet/` | `walletsProvider`, `totalBalanceProvider` | WalletRepository |
| Transactions | `screens/transaction/` | `transactionsProvider`, `transactionListItemsProvider`, `transactionFilterProvider`, `selectedMonthProvider` | TransactionRepository |
| Categories | (picker sheet inside transaction form) | `categoriesProvider` | TransactionRepository |
| Transfer | `screens/transfer/transfer_screen.dart` | `transfersProvider` | TransactionRepository |
