import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/prefs/settings_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();
  final settingsStore = SettingsStore(sharedPrefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsStore>.value(value: settingsStore),
      ],
      child: const MegaApp(),
    ),
  );
}
