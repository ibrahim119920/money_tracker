/// Konfigurasi publik untuk alur autentikasi aplikasi.
class AppAuthConfig {
  const AppAuthConfig._();

  /// Deep link yang digunakan Supabase untuk mengembalikan OAuth ke Android.
  /// URI ini juga harus ditambahkan pada Auth > URL Configuration di Supabase.
  static const String googleRedirectUri =
      'io.supabase.moneytracker://login-callback/';
}
