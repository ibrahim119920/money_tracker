# Money Tracker — Agent Entry Point

Welcome. This file is the starting point for AI agents and developers working in this repository.

---

## What This App Does

A personal finance management Flutter app for Indonesian users. Features: cashbook (buku kas) management, multiple wallets, income/expense tracking, monthly summaries. Backend is Supabase (PostgreSQL + Auth). Currency is IDR (Rupiah).

---

## Tech Stack at a Glance

| Concern | Package |
|---|---|
| Framework | Flutter (Dart) |
| State management | flutter_riverpod ^2.4.0 |
| Navigation | go_router ^13.2.0 |
| Backend | supabase_flutter ^2.3.0 (PostgreSQL + Auth) |
| Charts | fl_chart ^0.66.0 |
| Locale/currency | intl ^0.19.0 (locale: id_ID, currency: IDR) |
| Local cache | drift ^2.14.1 (⚠️ installed but NOT yet used) |

---

## Documentation Index

| File | What it answers |
|---|---|
| [docs/architecture.md](docs/architecture.md) | How layers interact, key design decisions, initialization order |
| [docs/project-map.md](docs/project-map.md) | Directory structure, every key file's purpose, DB tables |
| [docs/feature-modules.md](docs/feature-modules.md) | Feature-by-feature breakdown with file paths and status |
| [docs/state-management.md](docs/state-management.md) | All Riverpod providers, mutation pattern, what to invalidate |
| [docs/navigation-flow.md](docs/navigation-flow.md) | All routes, auth redirect logic, navigation patterns |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | Coding conventions, naming rules, do/don't list |
| [.github/PROJECT_DICTIONARY.md](.github/PROJECT_DICTIONARY.md) | Detailed class/file map, sprint log, debug checklist |

---

## Quick Orientation

### Where is X?

- **All Riverpod providers** → `lib/presentation/providers/providers.dart`
- **All routes** → `lib/app/router.dart` (`AppRoutes` class)
- **All entity types** → `lib/domain/entities/entities.dart`
- **All JSON models** → `lib/data/models/models.dart`
- **All Supabase CRUD** → `lib/data/repositories/cashbook_wallet_repository.dart`
- **Color constants** → `lib/core/constants/app_colors.dart`
- **UI strings (Indonesian)** → `lib/core/constants/app_strings.dart`
- **Currency format** → `lib/core/utils/currency_formatter.dart`
- **Date format** → `lib/core/utils/date_formatter.dart`

### Feature Status

| Feature | Status |
|---|---|
| Auth (Landing / Login / Register) | ✅ Complete |
| First-time setup wizard | ✅ Complete |
| Dashboard | ✅ Complete |
| Cashbook CRUD | ✅ Complete |
| Wallet CRUD + Detail | ✅ Complete |
| Transaction CRUD + Detail | ✅ Complete |
| Transfer between wallets | ✅ Complete |
| Monthly/annual reports | ✅ Monthly complete (annual pending) |
| Settings | ✅ P0 complete |
| Drift local cache | ⏳ Not started |

---

## Critical Rules (Never Break These)

1. **Never use `double`/`float` for money** — use `int` (integer Rupiah)
2. **Never hard delete** — set `is_deleted = true` (soft delete)
3. **Never access Supabase from a widget** — always go through a provider → repository
4. **Always `ref.invalidate()`** after any mutation (create/update/delete)
5. **Always call `initializeDateFormatting('id_ID', null)`** before `runApp()` in `main.dart`

---

## Common Task Recipes

### Add a new screen
1. Create `lib/presentation/screens/<feature>/<name>_screen.dart`
2. Extend `ConsumerWidget` or `ConsumerStatefulWidget`
3. Add a `GoRoute` in `lib/app/router.dart`
4. Add the path constant to `AppRoutes`

### Add a new provider
1. Add to `lib/presentation/providers/providers.dart`
2. Use `FutureProvider` for async data, `StateProvider` for UI state
3. Update [docs/state-management.md](docs/state-management.md)

### Add a repository method
1. Add to the appropriate class in `lib/data/repositories/cashbook_wallet_repository.dart`
2. Return domain entities (convert via `Model.fromJson().toEntity()`)
3. Wrap in `try/catch`; never bubble raw Supabase exceptions to the UI

### After completing work
- Update [.github/PROJECT_DICTIONARY.md](.github/PROJECT_DICTIONARY.md): timestamp, file map, sprint log entry
