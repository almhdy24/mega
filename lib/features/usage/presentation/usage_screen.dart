import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/format/bytes.dart';
import '../../../core/platform/usage_channel.dart';
import '../../../l10n/app_localizations.dart';
import 'usage_chart.dart';
import 'usage_view_model.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsageViewModel>().init();
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
      // Re-check permission and sync when returning from settings
      context.read<UsageViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final vm = context.watch<UsageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navUsage),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : () => vm.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            if (!vm.hasAccess) ...[
              _buildPermissionBanner(context, l10n, vm),
              const SizedBox(height: 16),
            ] else if (!vm.isMobileSupported) ...[
              _buildUnsupportedBanner(context, l10n),
              const SizedBox(height: 16),
            ] else if (vm.status == UsageResultStatus.error && vm.errorMessage != null) ...[
              _buildErrorBanner(context, vm),
              const SizedBox(height: 16),
            ],
            _buildPeriodSelector(context, l10n, isArabic, vm),
            const SizedBox(height: 20),
            _buildChartSection(context, l10n, isArabic, vm),
            const SizedBox(height: 20),
            _buildTopAppsSection(context, l10n, isArabic, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    UsageViewModel vm,
  ) {
    return Card(
      color: MegaColors.danger.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: MegaColors.danger.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: MegaColors.danger, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تعذر قراءة الاستهلاك: ${vm.errorMessage}',
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedBanner(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      color: MegaColors.warning.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: MegaColors.warning.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: MegaColors.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.usageMobileUnsupported,
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(
    BuildContext context,
    AppLocalizations l10n,
    UsageViewModel vm,
  ) {
    return Card(
      color: MegaColors.warning.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: MegaColors.warning.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: MegaColors.warning),
                const SizedBox(width: 8),
                Text(
                  l10n.usageAccessRequired,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.usagePermissionRationale,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => vm.openSettings(),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(l10n.usageOpenSettings),
              style: FilledButton.styleFrom(
                backgroundColor: MegaColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    UsageViewModel vm,
  ) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: MegaColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              tabs: [
                Tab(text: l10n.usageToday),
                Tab(text: l10n.usageCycle),
                Tab(text: l10n.usageMonth),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: TabBarView(
              children: [
                _buildStatsCard(context, l10n, isArabic, vm.todayTotals),
                _buildStatsCard(context, l10n, isArabic, vm.cycleTotals),
                _buildStatsCard(context, l10n, isArabic, vm.monthTotals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    UsageTotals totals,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.usageTotal,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  ByteFormatter.format(totals.grandTotal, isArabic: isArabic),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: MegaColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: MegaColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.usageMobile,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totals.mobileSupported
                                  ? ByteFormatter.format(totals.mobileTotal, isArabic: isArabic)
                                  : (isArabic ? 'غير مدعوم' : 'Unsupported'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: totals.mobileSupported ? 14 : 12,
                                color: totals.mobileSupported ? null : MegaColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? MegaColors.accent
                              : MegaColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.usageWifi,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ByteFormatter.format(totals.wifiTotal, isArabic: isArabic),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    UsageViewModel vm,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.usageHistory30Days,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: MegaColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(l10n.usageMobile, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? MegaColors.accent
                            : MegaColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(l10n.usageWifi, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            UsageBarChart(
              data: vm.chartData,
              isArabic: isArabic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    UsageViewModel vm,
  ) {
    final apps = vm.topApps;
    if (apps.isEmpty) return const SizedBox.shrink();

    final maxBytes = apps.first.mobileBytes > 0 ? apps.first.mobileBytes : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apps_outlined, color: MegaColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'أكثر التطبيقات استهلاكاً لبيانات الهاتف (اليوم)' : 'Top Apps by Mobile Data (Today)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final app = apps[i];
                final ratio = (app.mobileBytes / maxBytes).clamp(0.05, 1.0);
                final mobileStr = ByteFormatter.format(app.mobileBytes, isArabic: isArabic);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.appName.isNotEmpty ? app.appName : app.packageName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mobileStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: MegaColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                        color: MegaColors.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
