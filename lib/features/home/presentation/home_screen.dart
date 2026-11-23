import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/format/bytes.dart';
import '../../../core/platform/usage_channel.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/presentation/onboarding_sheet.dart';
import '../../usage/presentation/usage_chart.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeViewModel>().refresh();
    }
  }

  void _showRenewDialog(BuildContext context, HomeViewModel vm, AppLocalizations l10n) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.autorenew, color: MegaColors.primary),
            const SizedBox(width: 8),
            Text(l10n.homeRenewBundleNow, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          isArabic
              ? 'سيتم بدء دورة جديدة للباقة من الآن وحفظ استهلاك الدورة السابقة في السجل.'
              : 'A new bundle cycle will start now, and previous usage will be archived.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: MegaColors.primary),
            child: Text(l10n.homeRenewBundle),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        vm.renewBundleNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: MegaColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.appName,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isArabic ? 'تحديث' : 'Refresh',
            icon: vm.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : () => vm.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
          children: [
            // Error / System Status Banners
            if (!vm.hasAccess) ...[
              _buildPermissionBanner(context, l10n, vm),
              const SizedBox(height: 12),
            ] else if (vm.syncStatus == UsageResultStatus.error) ...[
              _buildSyncErrorBanner(context, isArabic),
              const SizedBox(height: 12),
            ] else if (vm.isDataOutdated) ...[
              _buildOutdatedDataBanner(context, isArabic),
              const SizedBox(height: 12),
            ],

            // A. Today's Usage (Primary)
            _buildTodaySection(context, isArabic, vm),
            const SizedBox(height: 12),

            // B. Bundle Status
            if (vm.hasBundle)
              _buildBundleSection(context, l10n, isArabic, vm)
            else
              _buildNoBundleSection(context, l10n, isArabic),
            const SizedBox(height: 16),

            // C. Usage History (Merged directly into Home)
            _buildHistorySection(context, isArabic, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context, AppLocalizations l10n, HomeViewModel vm) {
    return Card(
      elevation: 0,
      color: MegaColors.warning.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: MegaColors.warning.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: MegaColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.usageAccessRequired,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.usagePermissionRationale,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => vm.openSettings(),
                icon: const Icon(Icons.settings, size: 16),
                label: Text(l10n.usageOpenSettings),
                style: FilledButton.styleFrom(
                  backgroundColor: MegaColors.warning,
                  foregroundColor: Colors.black87,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncErrorBanner(BuildContext context, bool isArabic) {
    return Card(
      elevation: 0,
      color: MegaColors.danger.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: MegaColors.danger.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.sync_problem, color: MegaColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic
                    ? 'تعذر تحديث الاستهلاك الأخير. يتم عرض البيانات المحفوظة.'
                    : 'Failed to sync latest usage. Showing cached data.',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutdatedDataBanner(BuildContext context, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isArabic
                  ? 'البيانات قديمة — اسحب الشاشة للتحديث'
                  : 'Usage data may be outdated — pull down to refresh',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, bool isArabic, HomeViewModel vm) {
    final todayMobile = ByteFormatter.parseComponents(vm.todayMobileBytes, isArabic: isArabic);
    final todayWifiFormatted = ByteFormatter.format(vm.todayWifiBytes, isArabic: isArabic);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'استهلاك اليوم' : "Today's Consumption",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  DateFormat('d MMM', isArabic ? 'ar' : 'en').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hero Number: Today's Mobile Data
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  todayMobile.value >= 100
                      ? todayMobile.value.toStringAsFixed(0)
                      : todayMobile.value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: MegaColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  todayMobile.unit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'بيانات الجوال' : 'mobile',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Secondary: Wi-Fi usage
            Row(
              children: [
                Icon(
                  Icons.wifi,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  isArabic ? 'واي فاي: $todayWifiFormatted' : 'Wi-Fi: $todayWifiFormatted',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundleSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    HomeViewModel vm,
  ) {
    final remainingParsed = ByteFormatter.parseComponents(vm.remainingBytes, isArabic: isArabic);
    final totalFormatted = ByteFormatter.format(vm.totalBundleBytes, isArabic: isArabic);
    final safeDailyFormatted = ByteFormatter.format(vm.safeDailyAllowance, isArabic: isArabic);

    final usedPct = vm.usedPercentage;
    final isExpired = vm.isBundleExpired;

    Color progressColor = MegaColors.primary;
    if (usedPct >= 0.8) progressColor = MegaColors.warning;
    if (usedPct >= 1.0 || isExpired) progressColor = MegaColors.danger;

    final pace = vm.paceStatus;
    final paceText = isArabic ? pace.statusTextAr : pace.statusTextEn;

    final startStr = DateFormat('d MMM', isArabic ? 'ar' : 'en').format(vm.period.start);
    final endStr = DateFormat('d MMM', isArabic ? 'ar' : 'en').format(vm.period.end);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title & Days remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      isArabic ? 'الباقة' : 'Bundle',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$startStr – $endStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? MegaColors.danger.withValues(alpha: 0.12)
                        : MegaColors.primaryContainerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired ? l10n.homeBundleExpired : l10n.homeDaysLeft(vm.daysLeft),
                    style: TextStyle(
                      color: isExpired ? MegaColors.danger : MegaColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Remaining allowance
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  remainingParsed.value >= 100
                      ? remainingParsed.value.toStringAsFixed(0)
                      : remainingParsed.value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: MegaColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  remainingParsed.unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'متبقية من $totalFormatted' : 'remaining of $totalFormatted',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(usedPct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: usedPct,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                color: progressColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),

            // Row 4: Safe daily allowance & Pace Warning
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'المتاح يومياً: $safeDailyFormatted' : 'Safe daily: $safeDailyFormatted',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (pace.willExceed)
                  Text(
                    paceText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: MegaColors.warning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action: Renew bundle
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _showRenewDialog(context, vm, l10n),
                icon: const Icon(Icons.autorenew, size: 16),
                label: Text(l10n.homeRenewBundle),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBundleSection(BuildContext context, AppLocalizations l10n, bool isArabic) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Row(
          children: [
            const Icon(Icons.pie_chart_outline, size: 32, color: MegaColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeNoBundle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic
                        ? 'اضبط سعة باقتك لمتابعة الرصيد المتبقي'
                        : 'Set your bundle to track remaining data',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => OnboardingSheet.show(context),
              style: FilledButton.styleFrom(
                backgroundColor: MegaColors.primary,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(isArabic ? 'ضبط' : 'Set Up'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, bool isArabic, HomeViewModel vm) {
    final mobileTotalStr = ByteFormatter.format(vm.historyMobileTotal, isArabic: isArabic);
    final wifiTotalStr = ByteFormatter.format(vm.historyWifiTotal, isArabic: isArabic);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'سجل الاستهلاك' : 'Usage History',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 7,
                      label: Text(isArabic ? '7 أيام' : '7 Days', style: const TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: 30,
                      label: Text(isArabic ? '30 يوماً' : '30 Days', style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {vm.historyDays},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      vm.setHistoryDays(set.first);
                    }
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Summary of period
            Text(
              isArabic
                  ? 'إجمالي الفترة: $mobileTotalStr بيانات جوال · $wifiTotalStr واي فاي'
                  : 'Period total: $mobileTotalStr Mobile · $wifiTotalStr Wi-Fi',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),

            // Compact Bar Chart
            if (vm.historyData.isEmpty)
              Container(
                height: 140,
                alignment: Alignment.center,
                child: Text(
                  isArabic ? 'لا توجد بيانات كافية للرسم البياني' : 'No usage records available yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              UsageBarChart(
                data: vm.historyData,
                isArabic: isArabic,
              ),
          ],
        ),
      ),
    );
  }
}
