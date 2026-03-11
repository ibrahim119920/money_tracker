# Architecture — Money Tracker

## Overview

Money Tracker follows **Clean Architecture** with four distinct layers. Dependencies only flow inward: Presentation → Domain ← Data ← Core. No outer layer knows about an inner layer's implementation details.

```
┌──────────────────────────────────────┐
│           Presentation               │  Riverpod providers, screens, widgets
├──────────────────────────────────────┤
│             Domain                   │  Pure Dart entities & enums (no deps)
├──────────────────────────────────────┤
│              Data                    │  JSON models + Supabase repositories
├──────────────────────────────────────┤
│              Core                    │  Constants, formatters, validators
└──────────────────────────────────────┘
```

---

## Layers

### Core (`lib/core/`)
- Zero external dependencies — safe to use from any layer
- Provides: color constants, Indonesian strings, Rupiah formatter, date formatter (id_ID locale), form validators
- Key constraint: must call `initializeDateFormatting('id_ID', null)` in `main()` before using any `DateFormatter` method

### Domain (`lib/domain/`)
- Pure Dart — no Flutter, no Supabase imports
- Contains: entity classes (typed Dart objects), enums (`WalletType`, `TransactionType`, `RecurringFrequency`)
- Use cases directory exists but is currently empty; use case logic lives in repositories for now
- Entities are the single source of truth for data shapes throughout the app

### Data (`lib/data/`)
- **Models** (`lib/data/models/models.dart`): mirror the Supabase schema; each model has `fromJson()`, `toJson()`, `toEntity()`
- **Repositories** (`lib/data/repositories/cashbook_wallet_repository.dart`): all Supabase CRUD; three repository classes — `CashbookRepository`, `WalletRepository`, `TransactionRepository`
- Repositories return domain entities, never raw maps
- Soft delete pattern: `is_deleted = true` (never hard delete)
- Amounts stored as `BIGINT` (integer Rupiah, no floats)

### Presentation (`lib/presentation/`)
- **Providers** (`lib/presentation/providers/providers.dart`): all Riverpod state; single barrel file
- **Screens** (`lib/presentation/screens/`): one folder per feature, `ConsumerWidget`/`ConsumerStatefulWidget` throughout
- **Widgets** (`lib/presentation/widgets/`): shared reusable widgets

---

## Module Interaction

```
Widget (ConsumerWidget)
  │  ref.watch(xxxProvider)
  ▼
Riverpod Provider (FutureProvider / StateProvider)
  │  ref.read(xxxRepositoryProvider)
  ▼
Repository (CashbookRepository / WalletRepository / TransactionRepository)
  │  _client.from('table').select(...)
  ▼
Supabase (PostgreSQL)
  │  returns raw Map<String, dynamic>
  ▼
Model.fromJson() → Entity
  │  returned up the chain
  ▼
Widget renders entity data
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Single providers.dart barrel file | Simple to find all state; avoids scattering |
| Single repository file | Three repositories co-located; queries are related |
| `int` for currency amounts | Prevents floating-point rounding errors in financial data |
| Riverpod `ref.invalidate()` after mutations | Explicit cache busting; no stale data bugs |
| `setupInProgressProvider` flag | Prevents GoRouter from redirecting away during first-time onboarding wizard |
| Soft delete everywhere | Audit trail; recoverable mistakes; required by Supabase RLS pattern used |
| UUID primary keys | Unique across all tables; safe for offline generation |
| Supabase Auth as identity source | `auth.users` is separate from app `users` table; deleting from app table alone does not free the email |

---

## Initialization Sequence

1. `main()` calls `initializeDateFormatting('id_ID', null)` ← **must be first**
2. `Supabase.initialize(url, anonKey)` is called; failure shows `_AppInitErrorWidget`
3. `ProviderScope` wraps the app, making all Riverpod providers available
4. `goRouterProvider` starts at `/splash`; `authStateProvider` (StreamProvider) resolves
5. Router redirect fires: authenticated → `/dashboard`, unauthenticated → `/landing`

---

## Not Yet Implemented

- `lib/domain/usecases/` — empty; planned as a future abstraction layer
- `lib/presentation/screens/transfer/` — UI missing; provider exists
- `lib/presentation/screens/report/` — UI missing; route registered
- `lib/presentation/screens/settings/` — UI missing; route registered
- Drift local cache — dependency installed, no code uses it yet
- Recurring transactions — entity defined, no repository or UI
