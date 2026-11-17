// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MEGA';

  @override
  String get appTagline => 'Every byte counts';

  @override
  String get navHome => 'Home';

  @override
  String get navSpeedTest => 'Speed Test';

  @override
  String get navUsage => 'Usage';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeRemaining => 'Remaining Data';

  @override
  String homeOfBundle(String total) {
    return 'of $total';
  }

  @override
  String homeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get homeDailyAverage => 'Daily average';

  @override
  String get homeDailyTarget => 'Target daily pace';

  @override
  String get homeNoBundle => 'No bundle configured';

  @override
  String get homeSetBundle =>
      'Set up your bundle in Settings to track remaining data';

  @override
  String get homeLastSpeed => 'Last speed test';

  @override
  String get homeSpeedUnavailable => 'No speed tests recorded yet';

  @override
  String get speedStart => 'Start Test';

  @override
  String get speedTesting => 'Testing...';

  @override
  String get speedCancel => 'Cancel';

  @override
  String get speedPing => 'Ping';

  @override
  String get speedJitter => 'Jitter';

  @override
  String get speedDownload => 'Download';

  @override
  String get speedUpload => 'Upload';

  @override
  String get speedHistory => 'Test History';

  @override
  String get speedNoHistory => 'No tests recorded yet';

  @override
  String get speedMobileWarningTitle => 'Data Consumption Warning';

  @override
  String speedMobileWarningBody(String size) {
    return 'Running a speed test consumes mobile data (~$size). Do you want to proceed?';
  }

  @override
  String get speedProceed => 'Proceed';

  @override
  String get speedFailed => 'Test failed. Please check connection and server.';

  @override
  String get usageToday => 'Today';

  @override
  String get usageCycle => 'This Cycle';

  @override
  String get usageMonth => 'This Month';

  @override
  String get usageMobile => 'Mobile';

  @override
  String get usageWifi => 'Wi-Fi';

  @override
  String get usageTotal => 'Total';

  @override
  String get usageHistory30Days => 'Last 30 Days Usage';

  @override
  String get usageAccessRequired => 'Usage Access Required';

  @override
  String get usagePermissionRationale =>
      'MEGA needs Usage Access permission to read data consumption directly from your device. No data is ever transmitted off your phone.';

  @override
  String get usageOpenSettings => 'Open Settings';

  @override
  String get usagePermissionGranted => 'Access granted';

  @override
  String get usagePermissionMissing => 'Access needed';

  @override
  String get settingsBundleSize => 'Bundle Size (MB)';

  @override
  String get settingsCycleStart => 'Cycle Start Day';

  @override
  String settingsCycleDay(int day) {
    return 'Day $day of month';
  }

  @override
  String get settingsAlerts => 'Data Alerts';

  @override
  String get settingsAlertsDescription =>
      'Notify at 50%, 80%, and 100% of bundle';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsServer => 'Test Server URL';

  @override
  String get settingsUsagePermission => 'Usage Stats Permission';

  @override
  String get settingsAbout => 'About MEGA';

  @override
  String get settingsAboutDesc =>
      'Free, open-source, ultra-light internet monitor made with care for Sudan 🇸🇩';

  @override
  String get settingsLicense => 'MIT License · Elmahdi Dev';

  @override
  String get commonMb => 'MB';

  @override
  String get commonGb => 'GB';

  @override
  String get commonKb => 'KB';

  @override
  String get commonB => 'B';

  @override
  String get commonMbps => 'Mbps';

  @override
  String get commonMs => 'ms';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';
}
