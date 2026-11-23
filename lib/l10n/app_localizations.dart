import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MEGA'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Every byte counts'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining Data'**
  String get homeRemaining;

  /// No description provided for @homeOfBundle.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String homeOfBundle(String total);

  /// No description provided for @homeDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String homeDaysLeft(int count);

  /// No description provided for @homeDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily average'**
  String get homeDailyAverage;

  /// No description provided for @homeDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Target daily pace'**
  String get homeDailyTarget;

  /// No description provided for @homeNoBundle.
  ///
  /// In en, this message translates to:
  /// **'No bundle configured'**
  String get homeNoBundle;

  /// No description provided for @homeSetBundle.
  ///
  /// In en, this message translates to:
  /// **'Set up your bundle in Settings to track remaining data'**
  String get homeSetBundle;

  /// No description provided for @usageToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get usageToday;

  /// No description provided for @usageCycle.
  ///
  /// In en, this message translates to:
  /// **'This Cycle'**
  String get usageCycle;

  /// No description provided for @usageMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get usageMonth;

  /// No description provided for @usageMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get usageMobile;

  /// No description provided for @usageMobileUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Mobile data stats unsupported on Android < 10'**
  String get usageMobileUnsupported;

  /// No description provided for @usageWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get usageWifi;

  /// No description provided for @usageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get usageTotal;

  /// No description provided for @usageHistory30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days Usage'**
  String get usageHistory30Days;

  /// No description provided for @usageAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Usage Access Required'**
  String get usageAccessRequired;

  /// No description provided for @usagePermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'MEGA needs Usage Access permission to read data consumption directly from your device. No data is ever transmitted off your phone.'**
  String get usagePermissionRationale;

  /// No description provided for @usageOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get usageOpenSettings;

  /// No description provided for @usagePermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get usagePermissionGranted;

  /// No description provided for @usagePermissionMissing.
  ///
  /// In en, this message translates to:
  /// **'Access needed'**
  String get usagePermissionMissing;

  /// No description provided for @settingsBundleSize.
  ///
  /// In en, this message translates to:
  /// **'Bundle Size (GB)'**
  String get settingsBundleSize;

  /// No description provided for @settingsCycleStart.
  ///
  /// In en, this message translates to:
  /// **'Cycle Start Day'**
  String get settingsCycleStart;

  /// No description provided for @settingsCycleDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of month'**
  String settingsCycleDay(int day);

  /// No description provided for @settingsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Data Alerts'**
  String get settingsAlerts;

  /// No description provided for @settingsAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify at 50%, 80%, and 100% of bundle'**
  String get settingsAlertsDescription;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsUsagePermission.
  ///
  /// In en, this message translates to:
  /// **'Usage Stats Permission'**
  String get settingsUsagePermission;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About MEGA'**
  String get settingsAbout;

  /// No description provided for @settingsAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'Open-source mobile data monitor with live status bar meter.'**
  String get settingsAboutDesc;

  /// No description provided for @settingsLicense.
  ///
  /// In en, this message translates to:
  /// **'MIT License · Elmahdi Dev'**
  String get settingsLicense;

  /// No description provided for @commonMb.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get commonMb;

  /// No description provided for @commonGb.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get commonGb;

  /// No description provided for @commonKb.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get commonKb;

  /// No description provided for @commonB.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get commonB;

  /// No description provided for @commonMbps.
  ///
  /// In en, this message translates to:
  /// **'Mbps'**
  String get commonMbps;

  /// No description provided for @commonMs.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get commonMs;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @homeSafeDailyAllowance.
  ///
  /// In en, this message translates to:
  /// **'Safe daily allowance: {amount}'**
  String homeSafeDailyAllowance(String amount);

  /// No description provided for @homeRenewBundle.
  ///
  /// In en, this message translates to:
  /// **'Renew Bundle'**
  String get homeRenewBundle;

  /// No description provided for @homeRenewBundleNow.
  ///
  /// In en, this message translates to:
  /// **'Renew bundle now'**
  String get homeRenewBundleNow;

  /// No description provided for @homeBundleExpired.
  ///
  /// In en, this message translates to:
  /// **'Bundle Expired'**
  String get homeBundleExpired;

  /// No description provided for @homeTodayUsage.
  ///
  /// In en, this message translates to:
  /// **'Today: {mobile} Mobile · {wifi} Wi-Fi'**
  String homeTodayUsage(String mobile, String wifi);

  /// No description provided for @bundleSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Bundle'**
  String get bundleSetupTitle;

  /// No description provided for @bundleValidityDays.
  ///
  /// In en, this message translates to:
  /// **'Bundle Validity'**
  String get bundleValidityDays;

  /// No description provided for @bundleValidity1Day.
  ///
  /// In en, this message translates to:
  /// **'1 Day (Daily)'**
  String get bundleValidity1Day;

  /// No description provided for @bundleValidity7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days (Weekly)'**
  String get bundleValidity7Days;

  /// No description provided for @bundleValidity30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days (Monthly)'**
  String get bundleValidity30Days;

  /// No description provided for @bundleAutoRenewLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew when period ends'**
  String get bundleAutoRenewLabel;

  /// No description provided for @onboardingWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why does MEGA need this access?'**
  String get onboardingWhyTitle;

  /// No description provided for @onboardingWhyDesc.
  ///
  /// In en, this message translates to:
  /// **'MEGA reads your data consumption directly from system stats. Ad-free, login-free, tracker-free, and 100% offline-first on your device.'**
  String get onboardingWhyDesc;

  /// No description provided for @onboardingGrantButton.
  ///
  /// In en, this message translates to:
  /// **'Grant Usage Access'**
  String get onboardingGrantButton;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStartUsing.
  ///
  /// In en, this message translates to:
  /// **'Start Using MEGA'**
  String get onboardingStartUsing;

  /// No description provided for @liveNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Speed & Notification'**
  String get liveNotificationTitle;

  /// No description provided for @liveNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Show live speed in status bar and ongoing notification'**
  String get liveNotificationDesc;

  /// No description provided for @liveNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Live Notification Settings'**
  String get liveNotificationSettings;

  /// No description provided for @liveNotificationBatteryHelp.
  ///
  /// In en, this message translates to:
  /// **'If Live Notification Disappears'**
  String get liveNotificationBatteryHelp;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Required Permissions for MEGA'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingPermissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'MEGA requires usage statistics and notification access to display the real-time speed meter in your status bar and calculate bundle usage accurately:'**
  String get onboardingPermissionsDesc;

  /// No description provided for @onboardingUsagePermTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Usage Access'**
  String get onboardingUsagePermTitle;

  /// No description provided for @onboardingUsagePermDesc.
  ///
  /// In en, this message translates to:
  /// **'To calculate local cellular and Wi-Fi bundle consumption directly from system kernel.'**
  String get onboardingUsagePermDesc;

  /// No description provided for @onboardingNotifPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Status Bar'**
  String get onboardingNotifPermTitle;

  /// No description provided for @onboardingNotifPermDesc.
  ///
  /// In en, this message translates to:
  /// **'To display the real-time status bar speed icon and receive threshold alerts.'**
  String get onboardingNotifPermDesc;

  /// No description provided for @onboardingPermGranted.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get onboardingPermGranted;

  /// No description provided for @onboardingPermGrantAction.
  ///
  /// In en, this message translates to:
  /// **'Enable Access'**
  String get onboardingPermGrantAction;

  /// No description provided for @onboardingAutoStartLiveNotice.
  ///
  /// In en, this message translates to:
  /// **'Real-time status bar speed meter will be enabled automatically.'**
  String get onboardingAutoStartLiveNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
