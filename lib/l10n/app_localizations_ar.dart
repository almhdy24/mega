// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ميقا';

  @override
  String get appTagline => 'ميقابايتك محسوبة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get homeRemaining => 'المتبقي من الباقة';

  @override
  String homeOfBundle(String total) {
    return 'من أصل $total';
  }

  @override
  String homeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متبقي $count يوم',
      many: 'متبقي $count يوماً',
      few: 'متبقي $count أيام',
      two: 'متبقي يومان',
      one: 'متبقي يوم واحد',
      zero: 'اليوم الأخير',
    );
    return '$_temp0';
  }

  @override
  String get homeDailyAverage => 'المعدل اليومي الحالي';

  @override
  String get homeDailyTarget => 'المعدل المتاح للاستمرار';

  @override
  String get homeNoBundle => 'لم يتم ضبط باقة';

  @override
  String get homeSetBundle =>
      'اضبط حجم باقتك وتاريخ تجديدها في الإعدادات لمتابعة المتبقي';

  @override
  String get usageToday => 'اليوم';

  @override
  String get usageCycle => 'الدورة الحالية';

  @override
  String get usageMonth => 'هذا الشهر';

  @override
  String get usageMobile => 'بيانات الهاتف';

  @override
  String get usageMobileUnsupported =>
      'استهلاك الهاتف غير مدعوم في إصدار أندرويد هذا (يتطلب أندرويد 10 فأعلى)';

  @override
  String get usageWifi => 'واي فاي';

  @override
  String get usageTotal => 'الإجمالي';

  @override
  String get usageHistory30Days => 'استهلاك آخر 30 يوماً';

  @override
  String get usageAccessRequired => 'إذن الوصول للاستهلاك مطلوب';

  @override
  String get usagePermissionRationale =>
      'نحتاج إذن الوصول لإحصائيات الاستخدام لقراءة استهلاك الإنترنت. لا يتم إرسال أي بيانات خارج جهازك.';

  @override
  String get usageOpenSettings => 'فتح الإعدادات';

  @override
  String get usagePermissionGranted => 'تم منح الإذن';

  @override
  String get usagePermissionMissing => 'مطلوب تفعيل الإذن';

  @override
  String get settingsBundleSize => 'حجم الباقة (جيجابايت)';

  @override
  String get settingsCycleStart => 'يوم بداية الدورة';

  @override
  String settingsCycleDay(int day) {
    return 'يوم $day من الشهر';
  }

  @override
  String get settingsAlerts => 'تنبيهات الاستهلاك';

  @override
  String get settingsAlertsDescription =>
      'إشعار عند الوصول لـ 50% و80% و100% من الباقة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeSystem => 'تلقائي حسب النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsUsagePermission => 'إذن إحصائيات الاستخدام';

  @override
  String get settingsAbout => 'عن تطبيق ميقا';

  @override
  String get settingsAboutDesc =>
      'تطبيق مفتوح المصدر لمراقبة استهلاك باقات البيانات مع عداد حي في شريط الحالة.';

  @override
  String get settingsLicense => 'ترخيص MIT · المهدي ديف';

  @override
  String get commonMb => 'ميجابايت';

  @override
  String get commonGb => 'جيجابايت';

  @override
  String get commonKb => 'كيلوبايت';

  @override
  String get commonB => 'بايت';

  @override
  String get commonMbps => 'ميجابت/ث';

  @override
  String get commonMs => 'ملي ثانية';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String homeSafeDailyAllowance(String amount) {
    return 'تقدر تستهلك اليوم $amount';
  }

  @override
  String get homeRenewBundle => 'تجديد الباقة';

  @override
  String get homeRenewBundleNow => 'تجديد الباقة الآن';

  @override
  String get homeBundleExpired => 'انتهت الباقة';

  @override
  String homeTodayUsage(String mobile, String wifi) {
    return 'اليوم: $mobile بيانات · $wifi واي فاي';
  }

  @override
  String get bundleSetupTitle => 'ضبط الباقة';

  @override
  String get bundleValidityDays => 'مدة صلاحية الباقة';

  @override
  String get bundleValidity1Day => 'يوم واحد (يومي)';

  @override
  String get bundleValidity7Days => '7 أيام (أسبوعي)';

  @override
  String get bundleValidity30Days => '30 يوماً (شهري)';

  @override
  String get bundleAutoRenewLabel => 'تجديد تلقائي عند انتهاء المدة';

  @override
  String get onboardingWhyTitle => 'لماذا يحتاج ميقا هذا الإذن؟';

  @override
  String get onboardingWhyDesc =>
      'ميقا يقرأ استهلاك بياناتك بدقة من إحصائيات النظام مباشرة. بدون إعلانات، بدون تسجيل، بدون خوادم تتبع، ويعمل بالكامل على جهازك.';

  @override
  String get onboardingGrantButton => 'منح إذن الوصول للاستهلاك';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingStartUsing => 'ابدأ استخدام ميقا';

  @override
  String get liveNotificationTitle => 'الإشعار الحي وعداد السرعة';

  @override
  String get liveNotificationDesc =>
      'عرض السرعة الحية في شريط الحالة وإشعار مستمر';

  @override
  String get liveNotificationSettings => 'إعدادات الإشعار الحي';

  @override
  String get liveNotificationBatteryHelp => 'إذا اختفى الإشعار الحي';

  @override
  String get onboardingPermissionsTitle => 'الأذونات المطلوبة لتشغيل ميقا';

  @override
  String get onboardingPermissionsDesc =>
      'يحتاج التطبيق إلى إذن إحصائيات البيانات وإذن الإشعارات ليعمل العداد الحي في شريط الحالة ويحسب استهلاك باقتك بدقة:';

  @override
  String get onboardingUsagePermTitle => 'إذن إحصائيات الاستهلاك';

  @override
  String get onboardingUsagePermDesc =>
      'لقراءة حجم الميجابايتات المستهلكة من باقتك محلياً عبر الشريحة والواي فاي.';

  @override
  String get onboardingNotifPermTitle => 'إذن الإشعارات وشريط الحالة';

  @override
  String get onboardingNotifPermDesc =>
      'لعرض عداد السرعة الحي في شريط الحالة وإرسال تنبيهات استهلاك الباقة.';

  @override
  String get onboardingPermGranted => 'تم التفعيل';

  @override
  String get onboardingPermGrantAction => 'تفعيل الإذن';

  @override
  String get onboardingAutoStartLiveNotice =>
      'سيتم تشغيل عداد السرعة الحي في شريط الحالة تلقائياً.';
}
