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
  String get usageMobileUnsupported =>
      'Mobile data stats unsupported on Android < 10';

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
      'Open-source data monitor and lightweight network speed test.';

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

  @override
  String homeSafeDailyAllowance(String amount) {
    return 'Safe daily allowance: $amount';
  }

  @override
  String get homeRenewBundle => 'Renew Bundle';

  @override
  String get homeRenewBundleNow => 'Renew bundle now';

  @override
  String get homeQuickTest => 'Quick Test';

  @override
  String get homeBundleExpired => 'Bundle Expired';

  @override
  String homeTodayUsage(String mobile, String wifi) {
    return 'Today: $mobile Mobile · $wifi Wi-Fi';
  }

  @override
  String get bundleSetupTitle => 'Set Up Bundle';

  @override
  String get bundleValidityDays => 'Bundle Validity';

  @override
  String get bundleValidity1Day => '1 Day (Daily)';

  @override
  String get bundleValidity7Days => '7 Days (Weekly)';

  @override
  String get bundleValidity30Days => '30 Days (Monthly)';

  @override
  String get bundleAutoRenewLabel => 'Auto-renew when period ends';

  @override
  String get onboardingWhyTitle => 'Why does MEGA need this access?';

  @override
  String get onboardingWhyDesc =>
      'MEGA reads your data consumption directly from system stats. Ad-free, login-free, tracker-free, and 100% offline-first on your device.';

  @override
  String get onboardingGrantButton => 'Grant Usage Access';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStartUsing => 'Start Using MEGA';

  @override
  String get speedServer => 'Test Server';

  @override
  String get speedModeQuick => 'Quick (~4 MB)';

  @override
  String get speedModeFull => 'Full (~20 MB)';

  @override
  String get speedStabilityExcellent => 'Excellent';

  @override
  String get speedStabilityGood => 'Good';

  @override
  String get speedStabilityUnstable => 'Unstable';

  @override
  String get liveNotificationTitle => 'Live Speed & Notification';

  @override
  String get liveNotificationDesc =>
      'Show live speed in status bar and ongoing notification';

  @override
  String get liveNotificationSettings => 'Live Notification Settings';

  @override
  String get liveNotificationBatteryHelp => 'If Live Notification Disappears';

  @override
  String get onboardingPermissionsTitle => 'Required Permissions for MEGA';

  @override
  String get onboardingPermissionsDesc =>
      'MEGA requires usage statistics and notification access to display the real-time speed meter in your status bar and calculate bundle usage accurately:';

  @override
  String get onboardingUsagePermTitle => 'Data Usage Access';

  @override
  String get onboardingUsagePermDesc =>
      'To calculate local cellular and Wi-Fi bundle consumption directly from system kernel.';

  @override
  String get onboardingNotifPermTitle => 'Notifications & Status Bar';

  @override
  String get onboardingNotifPermDesc =>
      'To display the real-time status bar speed icon and receive threshold alerts.';

  @override
  String get onboardingPermGranted => 'Enabled';

  @override
  String get onboardingPermGrantAction => 'Enable Access';

  @override
  String get onboardingAutoStartLiveNotice =>
      'Real-time status bar speed meter will be enabled automatically.';
}
