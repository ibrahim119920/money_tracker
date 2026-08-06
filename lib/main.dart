import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/localization.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/constants/constants.dart';
import 'presentation/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android modern edge-to-edge mode. Individual screens protect their
  // interactive content with SafeArea/inset-aware scroll padding.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Inisialisasi locale data untuk format tanggal Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseKeys.supabaseUrl,
      anonKey: SupabaseKeys.supabaseAnonKey,
    );
  } catch (e) {
    runApp(const _AppInitErrorWidget());
    return;
  }

  runApp(const ProviderScope(child: MoneyTrackerApp()));
}

/// Widget fallback jika Supabase gagal diinisialisasi
class _AppInitErrorWidget extends StatelessWidget {
  const _AppInitErrorWidget();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Gagal terhubung ke server',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Periksa koneksi internet dan coba restart aplikasi.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoneyTrackerApp extends ConsumerWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      locale: appDefaultLocale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      builder: (context, child) {
        final brightness = themeMode == ThemeMode.dark
            ? Brightness.dark
            : themeMode == ThemeMode.light
            ? Brightness.light
            : MediaQuery.platformBrightnessOf(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemUiOverlayStyle(brightness),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerDelegate: goRouter.routerDelegate,
      routeInformationParser: goRouter.routeInformationParser,
      routeInformationProvider: goRouter.routeInformationProvider,
    );
  }
}
