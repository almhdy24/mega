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
            ],
            _buildPeriodSelector(context, l10n, isArabic, vm),
            const SizedBox(height: 20),
            _buildChartSection(context, l10n, isArabic, vm),
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
                              ByteFormatter.format(totals.mobileTotal, isArabic: isArabic),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
}
