import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/db/database.dart';
import 'core/platform/usage_channel.dart';
import 'core/prefs/settings_store.dart';
import 'features/speedtest/data/speedtest_repository.dart';
import 'features/speedtest/presentation/speedtest_view_model.dart';
import 'features/usage/data/usage_repository.dart';
import 'features/usage/presentation/usage_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();
  final settingsStore = SettingsStore(sharedPrefs);

  final db = await AppDatabase.getInstance();
  final usageSource = PlatformUsageSource();
  final usageRepository = UsageRepository(db: db, usageSource: usageSource);
  final speedTestRepository = SpeedTestRepository(db: db);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsStore>.value(value: settingsStore),
        Provider<UsageRepository>.value(value: usageRepository),
        Provider<SpeedTestRepository>.value(value: speedTestRepository),
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
          ),
        ),
      ],
      child: const MegaApp(),
    ),
  );
}
