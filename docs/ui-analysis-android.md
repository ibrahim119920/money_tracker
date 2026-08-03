# Analisis UI Android — Money Tracker

> Audit dilakukan pada 1 Agustus 2026. Laporan ini berfokus pada pengalaman pengguna Android, bukan audit keamanan backend atau audit skema Supabase.

## Ringkasan eksekutif

Money Tracker sudah memiliki fondasi UI yang baik untuk aplikasi keuangan pribadi: hierarki dashboard jelas, format Rupiah dan tanggal Indonesia konsisten di sebagian besar alur, mode terang/gelap tersedia, serta state loading dan empty state sudah dipikirkan. Dashboard adalah layar terkuat secara visual dan paling mendekati kualitas produk.

Setelah implementasi fase 1–3 dan verifikasi langsung pada perangkat Android, masalah P0 kontras, system bar/inset, dan dead CTA pada layar yang diuji sudah ditangani. Build belum production-ready karena branding Android masih default, release signing belum diverifikasi, annual report belum tersedia, dan matrix landscape/gesture-navigation/font-scale belum lengkap.

Penilaian indikatif:

| Area | Nilai | Catatan |
|---|---:|---|
| Hierarki dan visual dashboard | 7/10 | Ringkas, mudah dipindai, dan memiliki CTA utama yang jelas |
| Konsistensi light/dark theme | 7/10 | Layar prioritas sudah terbaca pada verifikasi langsung; responsive edge case masih ada |
| Android system integration | 7/10 | Edge-to-edge dan 3-button portrait tervalidasi; gesture, landscape, dan font scale belum |
| Aksesibilitas | 6/10 | UI Automator menemukan kontrol utama dan target prioritas 48dp; state/coverage belum lengkap |
| Kesiapan rilis | 6/10 | P0 UI membaik, tetapi icon/splash, signing, annual report, dan 50 lint issue tersisa |

Kesimpulan: aplikasi layak untuk internal beta setelah perbaikan P0, tetapi sebaiknya belum dipublikasikan sebelum masalah kontras dan inset Android diperbaiki.

## Status implementasi fase 1–3

Perubahan statis fase 1–3 sudah diterapkan setelah audit ini:

- semantic foreground colors dan `ColorScheme` light/dark diperbaiki;
- edge-to-edge, system bar, `SafeArea`, dan inset keyboard diterapkan pada layar utama/form;
- kontras report, transaction list/detail, wallet detail, transfer, filter, dan reusable transaction tile diperbaiki;
- wallet hero, transfer/transaction button, date picker locale, auth guard, reset password, dan dead CTA prioritas diperbaiki;
- override `titleTextStyle` ditambahkan setelah screenshot perangkat menemukan judul `Laporan Keuangan` dan `Detail Transaksi` tidak terlihat pada app bar terang.

Temuan pada bagian berikut tetap dipertahankan sebagai baseline audit dan alasan perubahan. Verifikasi visual langsung telah dilakukan setelah pengguna memberikan konfirmasi.

## Hasil verifikasi langsung Android

Pengujian dilakukan pada perangkat fisik `23122PCD1G` (Android 16/API 36, resolusi 1220 × 2712, density 480) menggunakan debug APK. APK berhasil dibuild dengan `flutter build apk --debug --no-pub` dan diinstal menggunakan `adb install -r`, sehingga data aplikasi tidak dihapus.

Layar yang diverifikasi:

- Light: dashboard, daftar transaksi berisi data, detail transaksi, laporan, dan settings.
- Dark: dashboard, laporan, settings, transfer, serta form pengeluaran dengan keyboard terbuka dan setelah keyboard ditutup.
- Interaksi: month picker, bottom navigation, FAB transaksi baru, transfer route, theme switcher, back navigation, dan UI Automator semantics.

Hasil utama:

- judul app bar terang yang semula hilang sudah tampil dengan kontras yang benar;
- foreground nominal/ikon, hero wallet, transfer lavender, report heading, filter, system bar, dan bottom inset terbaca pada layar yang diuji;
- UI Automator menemukan label dan target utama seperti `Back`, tab, `Simpan Transfer`, `Lihat Semua`, edit, dan delete;
- logcat 2.000 baris terakhir tidak memiliki marker crash, `FATAL EXCEPTION`, atau ANR; proses aplikasi tetap hidup;
- screenshot disimpan sementara di folder temp host dan tidak ditambahkan ke repository.

Residual yang masih perlu fase berikutnya:

1. Filter transaksi masih menggunakan horizontal viewport; ketika chip tipe dan tombol bulan penuh bersamaan, tepi chip kanan dapat terlihat terpotong dan affordance scroll belum eksplisit.
2. Form transaksi membuka keyboard numerik secara otomatis; ini mempercepat input, tetapi sementara menyembunyikan field bawah sampai keyboard ditutup. Keputusan autofocus dan scroll-to-focused-field perlu divalidasi.
3. Transfer history dapat menampilkan kartu terakhir sebagian pada viewport awal; konten dapat discroll, tetapi perlu verifikasi tambahan pada gesture navigation.
4. Landscape, gesture navigation, font scale besar, ukuran layar kecil, dan dynamic color belum diuji dalam sesi ini.

## Ruang lingkup dan metode

Audit dilakukan dengan kombinasi berikut:

- review kode widget, theme, routing, manifest, dan konfigurasi Android;
- menjalankan aplikasi pada perangkat Android 16 dengan resolusi 1220 × 2712 dan density 480;
- pemeriksaan alur dashboard, autentikasi, wallet, transaksi, transfer, laporan, settings, bottom sheet, keyboard, mode terang, dan mode gelap dalam portrait; landscape dicatat sebagai pekerjaan lanjutan;
- pemeriksaan semantics/UI Automator untuk kontrol utama;
- `dart analyze` sebagai pemeriksaan statis.

Data pengguna yang tampil pada perangkat tidak dimasukkan ke laporan ini.

## Hal yang sudah kuat

### Dashboard dan orientasi pengguna

- Kartu total saldo memakai visual yang dominan sehingga pengguna segera memahami kondisi keuangan.
- Ringkasan pemasukan/pengeluaran bulanan mudah dipindai.
- Kartu wallet horizontal cocok untuk beberapa dompet dan tidak memenuhi seluruh layar.
- FAB “Transaksi Baru” memberi jalur cepat ke tindakan utama.
- Bottom navigation memiliki empat tujuan yang mudah dipahami.
- Loading, skeleton/placeholder, pull-to-refresh, dan empty state sudah tersedia di beberapa alur penting.

### Form transaksi

- Input nominal menjadi fokus utama dan format IDR sesuai konteks aplikasi.
- Pemilihan tipe pemasukan/pengeluaran, kategori, wallet, tanggal, dan catatan mengikuti urutan mental model pencatatan transaksi.
- Bottom sheet pilihan tipe dan kategori lebih mudah digunakan daripada dropdown panjang.

### Fondasi tema dan semantics

- Material 3 dan `ColorScheme` sudah digunakan di [theme.dart](../lib/app/theme.dart).
- Tema dapat berganti antara sistem, terang, dan gelap serta disimpan melalui `SharedPreferences`.
- UI Automator dapat menemukan kontrol utama dan bottom navigation memiliki informasi tab, sehingga fondasi untuk screen reader sudah ada.

## Temuan prioritas tinggi

### P0 — Kontras mode gelap belum aman untuk data penting

> Status: mitigasi fase 1–3 sudah diverifikasi pada dashboard, report, settings, transfer, form pengeluaran, daftar transaksi, dan detail transaksi. Rincian di bawah adalah temuan baseline sebelum implementasi.

Beberapa widget masih menggunakan warna statis dari [app_colors.dart](../lib/core/constants/app_colors.dart), bukan warna semantik dari `Theme.of(context).colorScheme`. Akibatnya, warna yang cocok untuk latar terang dipakai di atas surface gelap.

Dampak yang terlihat:

- nilai dan ikon pada detail transaksi hampir hitam di atas kartu gelap;
- judul/label pada laporan bulanan (“Ringkasan Bulan Ini”, “Pemasukan”, “Pengeluaran”, dan “Distribusi Kategori”) hampir tidak terbaca;
- chip filter “Semua” dan ringkasan “Selisih Rp 0” pada daftar transaksi sangat redup;
- teks pada hero wallet detail menjadi gelap di atas gradient lavender;
- beberapa warna pada transfer menggunakan teks putih di atas lavender yang terlalu terang.

Rasio kontras indikatif yang dihitung dari palette saat ini:

| Kombinasi | Rasio kira-kira | Evaluasi |
|---|---:|---|
| `primary #1B3A3A` di atas `darkSurface #1E3535` | 1.06:1 | Gagal; hampir tidak terlihat |
| `textPrimary #1A2B2B` di atas `darkSurfaceContainer #234040` | 1.32:1 | Gagal |
| `transfer #B8A9E0` dengan teks putih | 2.15:1 | Gagal untuk teks normal |
| `textSecondary #8B9A9A` dengan latar putih | 2.92:1 | Terlalu rendah untuk teks kecil |
| `income #7ED957` dengan teks putih | 1.76:1 | Gagal |
| `expense #E53935` dengan teks putih | 4.23:1 | Masih di bawah 4.5:1 untuk teks normal |
| `textTertiary #9CA8A8` di atas latar terang | 1.87:1 | Terlalu rendah |

Perbaikan yang disarankan:

1. Gunakan `colorScheme.onSurface`, `onSurfaceVariant`, `primary`, `onPrimary`, dan warna container yang sesuai tema untuk teks/ikon umum.
2. Pisahkan warna semantic token dari warna dekoratif. Contohnya, `income` dan `expense` perlu memiliki pasangan `onIncome` dan `onExpense`, atau digunakan sebagai aksen/border dengan teks netral, bukan sebagai latar dengan teks putih secara otomatis.
3. Audit semua penggunaan langsung `AppColors.textPrimary`, `AppColors.primary`, `Colors.white`, dan `Colors.black` pada [transaction_detail_screen.dart](../lib/presentation/screens/transaction/transaction_detail_screen.dart), [monthly_report_screen.dart](../lib/presentation/screens/report/monthly_report_screen.dart), [transaction_list_screen.dart](../lib/presentation/screens/transaction/transaction_list_screen.dart), [wallet_detail_screen.dart](../lib/presentation/screens/wallet/wallet_detail_screen.dart), dan [transfer_screen.dart](../lib/presentation/screens/transfer/transfer_screen.dart).
4. Tambahkan golden/visual test minimal untuk kombinasi light dan dark pada layar laporan, detail transaksi, wallet detail, transfer, serta filter transaksi.

### P0 — Konten dapat tertutup navigation bar Android

> Status: pola edge-to-edge, system bar, `SafeArea`, dan bottom inset sudah diterapkan pada layar prioritas. Portrait dengan 3-button navigation tervalidasi; gesture, landscape, dan font scale masih menjadi pekerjaan lanjutan.

APK yang diuji menggunakan target SDK 36 melalui konfigurasi Flutter pada [android/app/build.gradle.kts](../android/app/build.gradle.kts). Pada Android modern, edge-to-edge dan system bar inset perlu diperlakukan secara eksplisit. Sebagian layar belum memakai `SafeArea` atau padding berbasis `MediaQuery` secara konsisten.

Dampak yang terlihat:

- bagian bawah settings, transfer, dan laporan dapat berada di bawah navigation bar hitam;
- chart dan label bulan laporan terpotong/terlalu dekat dengan system bar, terutama di landscape;
- history transfer dan tombol bawah berisiko sulit dijangkau pada perangkat dengan gesture navigation atau tiga tombol.

Perbaikan yang disarankan:

- bungkus konten scrollable dengan `SafeArea` atau tambahkan `MediaQuery.viewPaddingOf(context).bottom` ke padding akhir;
- pastikan `ListView`/`SingleChildScrollView` memiliki ruang ekstra untuk tombol terakhir;
- tetapkan warna system bar dan brightness ikon secara eksplisit untuk light/dark theme melalui konfigurasi system UI yang terpusat;
- uji Android 15/16 dengan gesture navigation dan 3-button navigation, portrait dan landscape, serta font scale besar;
- jangan hanya menambal satu layar: gunakan pola layout yang sama untuk settings, report, transfer, wallet detail, dan form.

### P0 — CTA terlihat tersedia tetapi belum berfungsi

> Status: dead CTA prioritas fase 1–3 sudah dihilangkan atau diberi status yang jujur. Tabel berikut mencatat kondisi setelah implementasi.

Temuan fungsional yang langsung memengaruhi kepercayaan pengguna:

| Lokasi | Temuan | Risiko |
|---|---|---|
| Login | “Lupa kata sandi?” kini membuka dialog dan mengirim reset email melalui repository | Alur pemulihan tersedia, tetapi perlu diuji dengan email nyata |
| Login | Google Sign-In dinonaktifkan dan diberi label “segera hadir” | Tidak lagi tampak sebagai CTA aktif yang gagal |
| Register | Teks syarat/ketentuan tidak lagi memiliki tap handler kosong | Link dokumen resmi masih dapat ditambahkan pada fase legal/content |
| Wallet detail | “Lihat Semua” membuka daftar transaksi | Dead end sudah dihilangkan |
| Landing/report | Klaim diubah menjadi laporan bulanan sesuai route yang tersedia | Annual report tetap backlog |

Implementasikan alurnya, atau sembunyikan/nonaktifkan CTA sampai siap. Untuk fitur yang memang belum tersedia, gunakan label “Segera hadir” yang tidak tampak seperti tombol aktif. Daftar route dan redirect dapat dirujuk di [router.dart](../lib/app/router.dart) dan [navigation-flow.md](navigation-flow.md).

Guard autentikasi juga sudah diperluas ke route protected wallet, transaksi, transfer, laporan, dan settings. Tetap perlu regression test ketika session berakhir saat route sedang terbuka.

## Temuan prioritas menengah

### Transfer: warna brand tidak memiliki pasangan foreground yang aman

> Status: foreground lavender, surface, outline, empty state, dan tombol transfer sudah memakai pasangan yang aman pada light/dark; screenshot transfer dark menunjukkan teks dan kontrol terbaca.

Temuan awal berasal dari AppBar dan tombol simpan transfer yang menggunakan lavender dengan teks putih. Implementasi sekarang menggunakan foreground gelap yang eksplisit, surface/theme-aware, dan empty state yang tidak bergantung pada `Colors.white`.

### Responsiveness dan landscape

Baris filter transaksi padat ketika tombol bulan, chip tipe, dan ringkasan tampil bersamaan. Pada layar kecil, teks panjang dan chip dapat menyempit atau terpotong. Laporan dengan chart juga belum memiliki layout khusus landscape; chart menjadi terlalu pendek dan area bawah dekat navigation bar.

Rekomendasi:

- gunakan `Wrap`/horizontal scroll yang memiliki affordance jelas untuk chip;
- pisahkan filter bulan dan filter tipe ketika lebar layar tidak cukup;
- gunakan breakpoint untuk mengubah chart menjadi layout dua kolom di landscape;
- uji nama cashbook/wallet panjang, nominal besar, bulan dengan data kosong, dan font scale 130–200%.

### Aksesibilitas

Semantics dasar sudah terdeteksi, tetapi beberapa target sentuh chip/toggle hasil dump berada sekitar 27dp tinggi, di bawah target 48dp yang disarankan untuk Android. Icon-only edit/delete pada detail transaksi juga belum memiliki tooltip yang jelas.

Perbaikan:

- pertahankan hit area minimal 48 × 48dp walaupun visual icon lebih kecil;
- tambahkan `tooltip` dan `Semantics(label:, button: true)` pada tombol icon-only;
- pastikan state selected, disabled, loading, dan error diumumkan ke screen reader;
- jangan mengandalkan warna saja untuk membedakan pemasukan dan pengeluaran; pertahankan label atau ikon;
- verifikasi kontras setelah dynamic color/font scale diterapkan.

### Keyboard dan form

> Verifikasi perangkat: keyboard numerik memang terbuka otomatis pada form pengeluaran dan menutupi field bawah sampai ditutup. Padding `viewInsets` sudah diterapkan; keputusan autofocus dan scroll-to-focused-field masih perlu divalidasi.

Field nominal pada form transaksi memakai autofocus sehingga keyboard langsung terbuka. Ini cepat untuk pengguna berpengalaman, tetapi dapat menutup tombol simpan dan membuat pengguna baru merasa layar “meloncat”. Date picker transaksi juga perlu dipastikan memakai locale `id_ID`, bukan hanya formatter di luar picker.

Gunakan `viewInsets`/scroll-to-focused-field, keyboard action yang sesuai, dan pastikan tombol simpan tetap terlihat. Berikan pilihan autofocus hanya jika memang tervalidasi sebagai keputusan UX yang diinginkan.

### Error, offline state, dan keamanan informasi

- Beberapa layar masih menampilkan `$error` atau pesan Supabase mentah. Tampilkan pesan yang ramah pengguna, simpan detail teknis di log, dan sediakan tombol “Coba lagi”.
- Karena Drift belum digunakan, UI perlu menangani koneksi lambat/putus tanpa membuat pengguna mengira data sudah tersimpan.
- Detail bank dan nomor akun sebaiknya dimasking secara default, dengan aksi reveal yang disengaja. Ini penting ketika layar terlihat di recent apps atau saat perangkat dipinjam.
- Loading screen sudah membantu alur inisialisasi, tetapi setiap screen yang gagal memuat data tetap memerlukan retry state yang konsisten.

### Navigasi dan konsistensi bahasa

Bottom navigation pada dashboard mendorong route baru dengan `push`, sementara halaman tujuan memiliki AppBar/back sendiri. Pengguna masih dapat kembali, tetapi tab aktif tidak persisten saat berada di halaman tujuan. Pertimbangkan `ShellRoute`/scaffold shell untuk empat area utama, atau tetapkan pola navigasi yang konsisten.

UI mencampur Bahasa Indonesia dengan “Dashboard”, “Wallet”, “Password”, “My Money”, dan label bahasa Inggris lain. Pilih satu bahasa utama untuk label pengguna; istilah teknis dapat dipertahankan bila memang bagian dari brand. Sentralisasi string di [app_strings.dart](../lib/core/constants/app_strings.dart) perlu diterapkan juga pada label yang masih hardcoded.

## Catatan per layar

> Tabel berikut mempertahankan baseline audit sebelum fase 1–3. Status aktual setelah verifikasi perangkat dirangkum di bawahnya.

| Layar | Yang bekerja | Perbaikan utama |
|---|---|---|
| Landing | Value proposition, CTA login/register, animasi masuk | Jangan mengiklankan annual report sebelum tersedia; finalisasi branding |
| Login/register | Struktur form dan validasi mudah dipahami | Implementasi lupa password, Google, terms; error harus user-friendly |
| Dashboard | Hierarki terbaik, saldo dan ringkasan mudah dipindai, FAB jelas | Navigasi tab, safe area, dan label bahasa perlu dirapikan |
| Cashbook/wallet list | CRUD dan empty state mudah dipahami | Kontras dark, nama panjang, privacy masking |
| Wallet detail | Hero saldo memberi konteks wallet | Teks hero dark di gradient lavender; “Lihat Semua” dead CTA |
| Transaction list | Grouping tanggal dan filter membantu scanning | Chip/ringkasan dark kurang kontras; target sentuh terlalu kecil |
| Transaction form | Alur input nominal dan kategori efektif | Keyboard menutup CTA; date picker locale; validasi/error state |
| Transaction detail | Hero nominal menonjol | Label, nilai, dan icon detail tidak terbaca di dark theme |
| Transfer | Form dan history memiliki struktur yang jelas | Lavender/white rendah kontras; empty state dan bottom inset |
| Monthly report | Month picker dan chart memberi gambaran finansial | Heading/label dark hampir hilang; landscape dan annual route |
| Settings | Pengelompokan kartu dan theme switch jelas | Konten/tombol bawah dapat tertutup navigation bar |

### Status layar setelah fase 1–3

| Layar | Status aktual | Residual |
|---|---|---|
| Landing | Klaim annual report sudah diselaraskan dengan laporan bulanan | Branding Android masih default |
| Login/register | Reset password tersedia; Google diberi status segera hadir; terms tidak lagi dead CTA | Legal/content link resmi masih dapat ditambahkan |
| Dashboard | Light/dark, system bar, dan portrait inset tervalidasi | Landscape, gesture navigation, dan font scale belum |
| Wallet detail | Hero dan `Lihat Semua` sudah diperbaiki | Masking nomor akun masih backlog |
| Transaction list | Kontras, semantics, dan target prioritas membaik | Filter packed masih perlu affordance scroll |
| Transaction form | Foreground, tombol, dan locale tanggal diperbaiki | Keyboard autofocus perlu keputusan UX |
| Transaction detail | App bar, label, nilai, dan ikon terbaca pada light/dark yang diuji | Tambahkan visual/accessibility test nyata |
| Transfer | Kontras lavender, surface, dan inset tervalidasi | Uji gesture navigation dan scroll akhir |
| Monthly report | Heading, app bar, chart labels, dan dark mode tervalidasi | Landscape dan annual report belum |
| Settings | Theme switch serta bottom inset portrait tervalidasi | Font scale dan gesture belum |

## Kesiapan Android dan branding

- Manifest saat ini hanya menggunakan label `money_tracker`, icon launcher default Flutter, dan permission internet. Ganti label/icon/splash untuk build rilis agar identitas produk konsisten.
- Splash masih memakai konfigurasi default putih; buat splash yang mengikuti brand dan tetap terbaca pada dark mode.
- Konfigurasi release masih perlu diverifikasi memakai signing key rilis, bukan debug key, sebelum distribusi ke Play Store.
- Tetapkan test matrix minimal: Android 13, 14, 15/16; gesture dan 3-button navigation; light/dark; portrait/landscape; font scale normal dan besar.

## Izin Android

### Status saat ini

Tidak ada izin runtime tambahan yang perlu diberikan pengguna untuk fitur yang sudah ada. Manifest mendeklarasikan:

| Izin | Kegunaan | Perlu prompt runtime? |
|---|---|---|
| `android.permission.INTERNET` | Akses Supabase Auth/database | Tidak; termasuk normal permission dan diberikan otomatis saat instalasi |

Aplikasi saat ini tidak membutuhkan kamera, lokasi, kontak, mikrofon, penyimpanan luas, notifikasi, atau biometrik. Jangan menambahkan izin tersebut hanya untuk berjaga-jaga.

### Jika fitur baru ditambahkan

- Notifikasi pengingat: `POST_NOTIFICATIONS` pada Android 13+ dan harus diminta pada konteks yang jelas.
- Kamera/foto profil: `CAMERA` atau media permission sesuai sumber gambar dan versi Android.
- Biometrik/app lock: `USE_BIOMETRIC`.
- Export CSV/PDF: utamakan Android Storage Access Framework/file picker agar tidak meminta broad storage permission.

 Pada proses audit, izin host satu kali untuk cache/config Flutter dan Dart diperlukan agar build, test, dan analyzer dapat berjalan. Itu adalah izin tool pemeriksaan, bukan izin runtime yang perlu diberikan kepada aplikasi Android, dan tidak mengubah data aplikasi.

## Verifikasi teknis

- `flutter build apk --debug --no-pub` berhasil menghasilkan APK dan APK berhasil diinstal ke perangkat fisik dengan `adb install -r`.
- `dart analyze` selesai tanpa error kompilasi yang dilaporkan, tetapi masih menghasilkan 50 warning/info, termasuk deprecated API, `print` di alur auth, parameter yang belum digunakan, dan beberapa lint style.
- `flutter test --no-pub` berhasil: smoke test lulus (`All tests passed!`). Test tersebut masih placeholder dan belum memverifikasi layar nyata.
- [test/widget_test.dart](../test/widget_test.dart) masih berupa smoke test placeholder (`MaterialApp` dengan teks “App loaded”), sehingga belum memverifikasi layar nyata.
- Audit visual manual fase 1–3 selesai pada perangkat Android 16. Screenshot/uji perangkat digunakan sebagai bukti audit, tetapi tidak disimpan sebagai data pengguna di repository.

## Rencana perbaikan berurutan

### P0 — sebelum beta publik

1. Selesaikan matrix Android: landscape, gesture navigation, font scale besar, layar kecil, dan dynamic color.
2. Rapikan filter transaksi pada lebar sempit dan putuskan strategi autofocus/scroll-to-focused-field.
3. Tambahkan test visual/accessibility nyata untuk dashboard, transaksi, transfer, report, dan settings.
4. Ganti icon, label, dan splash default; verifikasi signing release.
5. Siapkan annual report hanya setelah route, data, dan empty state siap.

### P1 — untuk kualitas harian

1. Perbaiki target sentuh, tooltip, semantics state, dan kontras teks sekunder.
2. Tangani keyboard, font scale, layar kecil, landscape, dan nama/nominal panjang.
3. Normalisasi error message, retry state, dan perilaku jaringan lambat/putus.
4. Masking nomor akun dan tinjau tampilan data sensitif di recent apps.

### P2 — penyempurnaan produk

1. Konsistenkan Bahasa Indonesia dan sentralisasi string.
2. Rapikan navigasi utama dengan shell/tab yang persisten.
3. Tambahkan annual report hanya setelah route, data, dan empty state siap.
4. Tambahkan widget/golden/accessibility test untuk alur finansial utama.

## Berkas rujukan

- [Theme dan ColorScheme](../lib/app/theme.dart)
- [Palet warna](../lib/core/constants/app_colors.dart)
- [Router dan auth redirect](../lib/app/router.dart)
- [Android manifest](../android/app/src/main/AndroidManifest.xml)
- [Konfigurasi Android build](../android/app/build.gradle.kts)
- [Dokumentasi navigasi](navigation-flow.md)
- [Dokumentasi modul fitur](feature-modules.md)
