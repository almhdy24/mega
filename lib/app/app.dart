import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../core/prefs/settings_store.dart';
import 'theme/theme.dart';
import 'shell.dart';

class MegaApp extends StatelessWidget {
  const MegaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();

    return MaterialApp(
      title: 'MEGA | ميقا',
      debugShowCheckedModeBanner: false,
      theme: MegaTheme.lightTheme(),
      darkTheme: MegaTheme.darkTheme(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ShellScreen(),
    );
  }
}
