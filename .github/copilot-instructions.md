# Money Tracker — GitHub Copilot Instructions

## ⚠️ SEBELUM MEMULAI TASK

**Copilot WAJIB:**
1. **Check dokumentasi `/docs` terlebih dahulu** — pahami konteks (khususnya: `feature-modules.md` untuk fitur yang relevan, `state-management.md` untuk provider, `navigation-flow.md` untuk routing)
   - Tidak perlu screening seluruh file, fokus pada bagian yang relevan dengan task
   - Gunakan `read_file` atau `search_subagent` untuk eksplorasi cepat
2. **Setelah task selesai, WAJIB update dokumentasi** — terutama `.github/PROJECT_DICTIONARY.md`:
   - Update timestamp di header
   - Update class/file map jika ada file/class baru atau perubahan signifikan
   - Update status screen jika berubah dari ⏳ ke ✅
   - Tambahkan sprint log entry dengan format terstruktur

**Ingat:** Dokumentasi adalah source of truth. Update docs = update project reality.

---

## Tech Stack
- Framework: Flutter (Dart)
- Backend/Cloud: Supabase (PostgreSQL + Auth)
- State Management: flutter_riverpod ^2.4.0
- Navigation: go_router ^13.2.0
- Local DB (cache): drift ^2.14.1
- HTTP Client: supabase_flutter ^2.3.0
- Format uang: intl ^0.19.0 (locale: id_ID, currency: IDR)

## Bahasa & Locale
- Semua teks UI menggunakan Bahasa Indonesia
- Format mata uang: Rupiah (Rp 1.000.000) — gunakan CurrencyFormatter di core/utils
- Format tanggal: Bahasa Indonesia (15 Januari 2024) — gunakan DateFormatter di core/utils
- Locale: id_ID

## Arsitektur — Clean Architecture
```
lib/
├── core/           → constants, utils, errors (tidak ada dependency ke layer lain)
├── data/           → models (JSON), repositories (akses Supabase)
├── domain/         → entities (pure Dart), usecases
└── presentation/   → providers (Riverpod), screens, widgets
```

## Konvensi Penamaan
- File: snake_case.dart
- Class: PascalCase
- Variable/method: camelCase
- Provider: xxxProvider (suffix Provider)
- Repository: XxxRepository
- Entity: XxxEntity
- Model: XxxModel
- Screen: XxxScreen
- Widget kecil: _XxxWidget (private, di dalam file screen)

## Supabase Pattern
- Client diambil dari: `ref.read(supabaseClientProvider)`
- Selalu handle error dengan try/catch
- Soft delete menggunakan kolom `is_deleted = true` (JANGAN hard delete)
- Amount disimpan sebagai BIGINT dalam satuan RUPIAH BULAT (bukan float/double)
- UUID untuk semua primary key

## State Management — Riverpod
- Gunakan `FutureProvider` untuk async data dari Supabase
- Gunakan `StateProvider` untuk state UI sederhana (filter, selected item)
- Gunakan `Provider` untuk dependency injection (repository, service)
- Selalu `ref.invalidate(xxxProvider)` setelah mutation (create/update/delete)
- Pattern refresh: invalidate provider → UI otomatis rebuild

## Pola Repository
```dart
// Selalu ikuti pola ini:
Future<XxxEntity> createXxx({required String param}) async {
  final data = await _client.from('table').insert({...}).select().single();
  return XxxModel.fromJson(data).toEntity();
}
```

## Widget Conventions
- Selalu gunakan `ConsumerWidget` atau `ConsumerStatefulWidget` (bukan StatelessWidget)
- Loading state: tampilkan `CircularProgressIndicator`
- Error state: tampilkan pesan error + tombol retry
- Empty state: tampilkan ilustrasi + pesan kosong
- Gunakan `AsyncValue.when(data, loading, error)` untuk handle state

## Color Constants (gunakan AppColors dari core/constants/app_colors.dart)
- Income/Pemasukan: AppColors.income (#43A047 hijau)
- Expense/Pengeluaran: AppColors.expense (#E53935 merah)
- Transfer: AppColors.transfer (#8E24AA ungu)
- Primary: AppColors.primary (#1E88E5 biru)

## Validasi Form
- Gunakan Validators dari core/utils/validators.dart
- Selalu validasi di client side sebelum kirim ke Supabase
- Amount input: format otomatis dengan titik ribuan saat mengetik

## Error Handling
- Tampilkan error via SnackBar dengan warna AppColors.error
- Sukses: SnackBar dengan warna AppColors.success
- Jangan expose technical error ke user, gunakan pesan friendly

## Do & Don't
✅ DO:
- Gunakan const constructor bila memungkinkan
- Extract widget kecil ke method/class terpisah jika > 50 baris
- Gunakan named parameters untuk konstruktor
- Handle semua state: loading, error, data kosong
- Selalu dispose TextEditingController & AnimationController

❌ DON'T:
- Jangan gunakan double/float untuk menyimpan amount uang
- Jangan hard delete data (gunakan soft delete)
- Jangan akses Supabase langsung dari widget/screen
- Jangan gunakan setState di ConsumerStatefulWidget untuk data dari provider
- Jangan lupa unsubscribe dari stream

---

## Documentation

Dokumentasi lengkap tersedia di folder `docs/` dan file-file berikut:

| File | Isi |
|---|---|
| `AGENTS.md` | AI agent entry point — orientasi cepat |
| `docs/architecture.md` | Arsitektur Clean Architecture, layer interaction, design decisions |
| `docs/project-map.md` | Struktur direktori, setiap file penting dan tanggung jawabnya |
| `docs/feature-modules.md` | Breakdown per fitur: file, status, business logic |
| `docs/state-management.md` | Semua provider Riverpod, mutation pattern, invalidation map |
| `docs/navigation-flow.md` | Semua route, auth redirect logic, pola navigasi |
| `.github/PROJECT_DICTIONARY.md` | Class/file map, sprint log, debug checklist |

**Urutan baca yang disarankan saat orientasi:**
1. `AGENTS.md` — overview
2. `docs/architecture.md` — cara kerja layer
3. `docs/feature-modules.md` — status fitur
4. `docs/state-management.md` — sebelum menambah provider
5. `docs/navigation-flow.md` — sebelum menambah route

### ⚠️ PENTING: Wajib Update Dokumentasi Setelah Selesai Kerja
**SETELAH SETIAP PEKERJAAN SELESAI, WAJIB memperbarui `.github/PROJECT_DICTIONARY.md`:**
1. Update **timestamp** di header
2. Update **class/file map** jika ada file/class baru atau perubahan signifikan
3. Update **status screen** jika ada screen yang berubah dari ⏳ ke ✅
4. Tambahkan **items baru di Sprint Log** dengan format:
```markdown
### ✅ **Sprint X.X — Feature Name DONE (Date)**
**Items:**
- [x] Deskripsi fitur/fix
- [x] File yang berubah (path relative)
- [x] Catatan teknis jika ada
```
5. Update file di `docs/` yang relevan jika arsitektur berubah

### Quick Reference — File Penting

| Kebutuhan | File |
|---|---|
| Warna, string UI | `lib/core/constants/app_colors.dart`, `app_strings.dart` |
| Format uang / tanggal | `lib/core/utils/currency_formatter.dart`, `date_formatter.dart` |
| Validasi form | `lib/core/utils/validators.dart` |
| Semua entity (domain model) | `lib/domain/entities/entities.dart` |
| Semua model (JSON ↔ entity) | `lib/data/models/models.dart` |
| Repository (Supabase CRUD) | `lib/data/repositories/cashbook_wallet_repository.dart` |
| Semua provider Riverpod | `lib/presentation/providers/providers.dart` |
| Routing & konstanta path | `lib/app/router.dart` |

### Fitur Yang Belum Diimplementasi (⏳)
- `lib/presentation/screens/transfer/` — Transfer antar wallet
- `lib/presentation/screens/report/` — Laporan bulanan
- `lib/presentation/screens/settings/` — Pengaturan
- `lib/domain/usecases/` — Use cases layer (kosong)
- Drift local cache — dependency ada di pubspec, belum dipakai

### Providers Yang Perlu di-invalidate Setelah Mutasi Transaksi
```dart
ref.invalidate(transactionsProvider);
ref.invalidate(walletsProvider);
ref.invalidate(totalBalanceProvider);
ref.invalidate(monthlySummaryProvider);
```
