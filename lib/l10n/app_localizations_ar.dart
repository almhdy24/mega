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
  String get appTagline => 'متابعة دقيقة لاستهلاك باقة الإنترنت';

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
      'اضبط سعة باقتك وتاريخ بدئها لمتابعة الرصيد المتبقي';

  @override
  String get usageToday => 'اليوم';

  @override
  String get usageCycle => 'الدورة الحالية';

  @override
  String get usageMonth => 'هذا الشهر';

  @override
  String get usageMobile => 'بيانات الجوال';

  @override
  String get usageMobileUnsupported =>
      'قراءة استهلاك بيانات الجوال تتطلب أندرويد 10 فأعلى';

  @override
  String get usageWifi => 'واي فاي';

  @override
  String get usageTotal => 'الإجمالي';

  @override
  String get usageHistory30Days => 'استهلاك آخر 30 يوماً';

  @override
  String get usageAccessRequired => 'إذن إحصائيات الاستخدام مطلوب';

  @override
  String get usagePermissionRationale =>
      'يحتاج ميقا إذن إحصائيات الاستخدام لقراءة استهلاك باقتك محلياً من النظام. لا تغادر أي بيانات هاتفك.';

  @override
  String get usageOpenSettings => 'فتح الإعدادات';

  @override
  String get usagePermissionGranted => 'تم التفعيل';

  @override
  String get usagePermissionMissing => 'يحتاج تفعيل';

  @override
  String get settingsBundleSize => 'سعة الباقة';

  @override
  String get settingsCycleStart => 'يوم بداية الباقة';

  @override
  String settingsCycleDay(int day) {
    return 'يوم $day من الشهر';
  }

  @override
  String get settingsAlerts => 'تنبيهات الاستهلاك';

  @override
  String get settingsAlertsDescription =>
      'تنبيه عند بلوغ 50% و80% و100% من سعة الباقة';

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
      'تطبيق محلي لمراقبة استهلاك باقات الجوال مع عداد سرعة حي في شريط الحالة.';

  @override
  String get settingsLicense => 'ترخيص MIT · تطوير Elmahdi Dev';

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
    return 'المعدل اليومي المقترح: $amount';
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
  String get onboardingWhyTitle => 'متابعة دقيقة لباقة هاتفك';

  @override
  String get onboardingWhyDesc =>
      'يعرض ميقا استهلاك بيانات الجوال المتبقي من باقتك ومعدل الصرف اليومي. تطبيق محلي خفيف، بدون إعلانات، وبدون أي اتصال خارجي.';

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
      'عرض سرعة التحميل والرفع في شريط الحالة وإشعار مستمر';

  @override
  String get liveNotificationSettings => 'إعدادات الإشعار الحي';

  @override
  String get liveNotificationBatteryHelp => 'إذا اختفى الإشعار الحي';

  @override
  String get onboardingPermissionsTitle => 'أذونات تشغيل ميقا';

  @override
  String get onboardingPermissionsDesc =>
      'يعتمد ميقا على قراءة إحصائيات النظام مباشرة دون الحاجة لأي خوادم خارجية:';

  @override
  String get onboardingUsagePermTitle => 'إذن إحصائيات الاستخدام (أساسي)';

  @override
  String get onboardingUsagePermDesc =>
      'لقراءة استهلاك بيانات الجوال والواي فاي بدقة من نظام أندرويد.';

  @override
  String get onboardingNotifPermTitle => 'إذن الإشعارات (اختياري)';

  @override
  String get onboardingNotifPermDesc =>
      'لعرض عداد السرعة في شريط الحالة وتنبيهك قبل نفاد باقتك.';

  @override
  String get onboardingPermGranted => 'مفعّل';

  @override
  String get onboardingPermGrantAction => 'تفعيل الإذن';

  @override
  String get onboardingAutoStartLiveNotice =>
      'يمكنك التحكم في تشغيل عداد السرعة وتخصيصه دائماً من الإعدادات.';
}
