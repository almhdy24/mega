import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/format/bytes.dart';
import '../../../core/format/speed.dart';
import '../../../l10n/app_localizations.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().refresh();
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
            Text(
              l10n.appName,
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(width: 8),
            Text(
              '· ${l10n.appTagline}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
            if (!vm.hasBundle)
              _buildNoBundleCard(context, l10n)
            else
              _buildBundleHero(context, l10n, isArabic, vm),
            const SizedBox(height: 16),
            if (vm.hasBundle) ...[
              _buildPaceComparison(context, l10n, isArabic, vm),
              const SizedBox(height: 16),
            ],
            _buildLastSpeedCard(context, l10n, isArabic, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBundleCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          children: [
            const Icon(Icons.pie_chart_outline, size: 48, color: MegaColors.primary),
            const SizedBox(height: 12),
            Text(
              l10n.homeNoBundle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeSetBundle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundleHero(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    HomeViewModel vm,
  ) {
    final remainingParsed = ByteFormatter.parseComponents(vm.remainingBytes, isArabic: isArabic);
    final totalFormatted = ByteFormatter.format(vm.totalBundleBytes, isArabic: isArabic);
    final usedFormatted = ByteFormatter.format(vm.usedMobileBytes, isArabic: isArabic);
    final usedPct = vm.usedPercentage;

    Color progressColor = MegaColors.primary;
    if (usedPct >= 0.8) progressColor = MegaColors.warning;
    if (usedPct >= 1.0) progressColor = MegaColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeRemaining,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MegaColors.primaryContainerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.homeDaysLeft(vm.daysLeft),
                    style: const TextStyle(
                      color: MegaColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  remainingParsed.value >= 100
                      ? remainingParsed.value.toStringAsFixed(0)
                      : remainingParsed.value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: MegaColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  remainingParsed.unit,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.homeOfBundle(totalFormatted),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: usedPct,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                color: progressColor,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(usedPct * 100).toStringAsFixed(0)}% استُهلك ($usedFormatted)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  totalFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceComparison(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    HomeViewModel vm,
  ) {
    final dailyAvgStr = ByteFormatter.format(vm.dailyAverageBytes, isArabic: isArabic);
    final dailyTargetStr = ByteFormatter.format(vm.dailyTargetBytes, isArabic: isArabic);

    final isPaceHigh = vm.dailyAverageBytes > vm.dailyTargetBytes && vm.dailyTargetBytes > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeDailyAverage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dailyAvgStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPaceHigh ? MegaColors.warning : MegaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeDailyTarget,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dailyTargetStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MegaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSpeedCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    HomeViewModel vm,
  ) {
    final last = vm.lastSpeedResult;

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
                  l10n.homeLastSpeed,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.speed, size: 20, color: MegaColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            if (last == null)
              Text(
                l10n.homeSpeedUnavailable,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        l10n.speedDownload,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        SpeedFormatter.formatMbps(last.downMbps, isArabic: isArabic),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MegaColors.primary),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        l10n.speedUpload,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        SpeedFormatter.formatMbps(last.upMbps, isArabic: isArabic),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        l10n.speedPing,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        SpeedFormatter.formatMs(last.pingMs, isArabic: isArabic),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  DateFormat.yMMMd(isArabic ? 'ar' : 'en')
                      .add_jm()
                      .format(DateTime.fromMillisecondsSinceEpoch(last.ts)),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
