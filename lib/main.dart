import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/db/database.dart';
import 'core/platform/usage_channel.dart';
import 'core/prefs/settings_store.dart';
import 'features/home/presentation/home_view_model.dart';
import 'features/speedtest/data/speedtest_repository.dart';
import 'features/speedtest/presentation/speedtest_view_model.dart';
import 'features/usage/data/usage_repository.dart';
import 'features/usage/presentation/usage_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  try {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en', null);

    final db = await AppDatabase.getInstance();
    final sharedPrefs = await SharedPreferences.getInstance();
    final settingsStore = SettingsStore(sharedPrefs);

    final usageSource = PlatformUsageSource();
    final usageRepository = UsageRepository(db: db, usageSource: usageSource);
    final speedTestRepository = SpeedTestRepository(db: db);

    // If alerts are enabled and bundle is configured, schedule WorkManager
    if (settingsStore.alertsEnabled && settingsStore.bundleBytes > 0) {
      usageSource.scheduleAlertWorker();
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsStore>.value(value: settingsStore),
          Provider<UsageRepository>.value(value: usageRepository),
          Provider<SpeedTestRepository>.value(value: speedTestRepository),
          ChangeNotifierProvider<HomeViewModel>(
            create: (_) => HomeViewModel(
              usageRepository: usageRepository,
              speedRepository: speedTestRepository,
              settings: settingsStore,
              usageSource: usageSource,
            ),
          ),
          ChangeNotifierProvider<UsageViewModel>(
            create: (_) => UsageViewModel(
              repository: usageRepository,
              settings: settingsStore,
            ),
          ),
          ChangeNotifierProvider<SpeedTestViewModel>(
            create: (_) => SpeedTestViewModel(
              repository: speedTestRepository,
              settings: settingsStore,
              usageSource: usageSource,
            ),
          ),
        ],
        child: const MegaApp(),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8),
            surface: Color(0xFF1E293B),
          ),
        ),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'حدث خطأ غير متوقع أثناء تشغيل التطبيق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'An unexpected error occurred while starting the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => main(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة / Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Theme(
                      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Text(
                          'تفاصيل الخطأ / Technical details',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              '$error',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
