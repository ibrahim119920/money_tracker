# 🚀 Money Tracker - Initial Setup Guide

Selamat! Saya sudah membuat struktur dasar project Money Tracker sesuai dengan panduan Clean Architecture dan tech stack yang ditentukan.

## ✅ Sudah Selesai

- [x] Setup pubspec.yaml dengan semua dependencies
- [x] Buat struktur folder Clean Architecture (core, data, domain, presentation)
- [x] Setup constants (app_colors, app_strings, supabase_keys)
- [x] Setup utils (currency_formatter, date_formatter, validators)
- [x] Buat domain entities dan enums
- [x] Buat data models dengan JSON serialization
- [x] Setup Riverpod providers (auth, cashbook, wallet, transaction, transfer, dll)
- [x] Setup GoRouter dengan route guards
- [x] Setup Material 3 theme
- [x] Setup main.dart dengan Supabase initialization
- [x] Buat placeholder screens (login, register, dashboard)
- [x] flutter pub get (dependencies installed)

## 📋 Langkah Selanjutnya

### 1. **Konfigurasi Supabase Keys** (CRITICAL)
   - Buka file: `lib/core/constants/supabase_keys.dart`
   - Ganti `YOUR_SUPABASE_URL` dengan URL Supabase project Anda
   - Ganti `YOUR_SUPABASE_ANON_KEY` dengan Anon Key dari Supabase
   - Dapatkan dari: Supabase Dashboard → Settings → API
   - **JANGAN push ke git!** (sudah di .gitignore)

   ```dart
   // Contoh:
   static const String supabaseUrl = 'https://xxxxxxxxxx.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

### 2. **Setup Database di Supabase**
   - Buat tabel di Supabase sesuai dengan schema yang ada di `.github/01_project_overview_database.md`
   - Atau gunakan SQL script di bawah untuk membuat tabel otomatis
   - Enable RLS pada semua tabel
   - Setup auth trigger untuk membuat row di tabel `users` saat register

### 3. **Implementasi Auth Screens** (Sprint 1)
   - Implement `LoginScreen` di `lib/presentation/screens/auth/login_screen.dart`
   - Implement `RegisterScreen` di `lib/presentation/screens/auth/register_screen.dart`
   - Setup auth repository di `lib/data/repositories/auth_repository.dart`
   - Setup auth providers (sign up, sign in, sign out, forget password)

### 4. **Implementasi Dashboard** (Sprint 2)
   - Setup wallet & cashbook repository
   - Implement `DashboardScreen` dengan:
     - Cashbook switcher
     - Total saldo display
     - Wallet cards
     - Recent transactions list
     - Quick action buttons

### 5. **Setup Database Triggers** (Supabase/PostgreSQL)
   - Buat trigger untuk auto-update `wallets.current_balance` saat transaksi
   - Buat trigger untuk auto-update `updated_at` field

## 📁 Struktur Project Sekarang

```
lib/
├── main.dart (entry point dengan Riverpod & Supabase)
├── app/
│   ├── router.dart (GoRouter setup dengan auth guard)
│   └── theme.dart (Material 3 theme configuration)
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   ├── supabase_keys.dart (⚠️ TO DO: isi dengan key Supabase)
│   │   └── constants.dart (barrel export)
│   └── utils/
│       ├── currency_formatter.dart (Format Rp)
│       ├── date_formatter.dart (Format tanggal ID)
│       ├── validators.dart (Form validation)
│       └── utils.dart (barrel export)
├── data/
│   ├── models/
│   │   └── models.dart (semua model: User, Cashbook, Wallet, Category, Transaction, Transfer)
│   └── repositories/ (TO DO: implement repositories)
├── domain/
│   ├── entities/
│   │   └── entities.dart (pure Dart classes + enums)
│   └── usecases/ (TO DO: implement usecases)
└── presentation/
    ├── providers/
    │   └── providers.dart (Riverpod providers setup)
    └── screens/
        ├── auth/
        │   ├── login_screen.dart (placeholder)
        │   └── register_screen.dart (placeholder)
        ├── dashboard/
        │   └── dashboard_screen.dart (placeholder)
        ├── cashbook/ (TO DO: implement)
        ├── wallet/ (TO DO: implement)
        ├── transaction/ (TO DO: implement)
        ├── transfer/ (TO DO: implement)
        ├── report/ (TO DO: implement)
        └── settings/ (TO DO: implement)
```

## 🔑 Key Features Sudah Setup

| Feature | Status | File |
|---------|--------|------|
| Flutter Riverpod (State Management) | ✅ | `lib/presentation/providers/providers.dart` |
| GoRouter (Navigation + Auth Guard) | ✅ | `lib/app/router.dart` |
| Supabase Client | ✅ | `lib/main.dart` |
| Material 3 Theme | ✅ | `lib/app/theme.dart` |
| Currency Formatter (Rp) | ✅ | `lib/core/utils/currency_formatter.dart` |
| Date Formatter (ID) | ✅ | `lib/core/utils/date_formatter.dart` |
| Form Validators | ✅ | `lib/core/utils/validators.dart` |
| Clean Architecture Structure | ✅ | Folder structure |

## 🚦 Cara Menjalankan

1. Setup supabase_keys.dart terlebih dahulu
2. `flutter pub get` (sudah dilakukan)
3. `flutter run` 

## 📚 Referensi & Panduan

- [Panduan Database Schema](../.github/01_project_overview_database.md)
- [Panduan Arsitektur & Sprint Plan](../.github/02_arsitektur_sprint_plan.md)
- [GitHub Copilot Coding Guide](../.github/copilot-instructions.md)

## 💡 Tips

- Gunakan `ConsumerWidget` atau `ConsumerStatefulWidget` untuk akses providers di UI
- Selalu gunakan `ref.invalidate(xxxProvider)` setelah mutation (create/update/delete)
- Check AppStrings untuk teks dalam Bahasa Indonesia
- Check AppColors untuk konsistensi warna
- Amount disimpan dalam BIGINT (rupiah), bukan double!

---

**Status**: Project setup completed ✅
**Next**: Implement Auth screens & database setup
