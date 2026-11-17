import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/format/bytes.dart';
import '../../../core/format/speed.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/presentation/onboarding_sheet.dart';
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
        content: const Text(
          'سيتم بدء دورة جديدة للباقة من الآن وحفظ استهلاك الدورة السابقة في السجل.',
          style: TextStyle(fontSize: 14, height: 1.4),
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
            // 1. Permission warning card if access missing
            if (!vm.hasAccess) ...[
              _buildPermissionCard(context, l10n, vm),
              const SizedBox(height: 16),
            ],

            // 2. Hero card or onboarding card if no bundle
            if (!vm.hasBundle)
              _buildOnboardingCard(context, l10n)
            else
              _buildBundleHero(context, l10n, isArabic, vm),

            const SizedBox(height: 16),

            // 3. Two big action buttons: Quick test & Renew bundle
            _buildActionButtons(context, l10n, vm),

            const SizedBox(height: 16),

            // 4. Quick Test live card (if running or just finished)
            if (vm.isQuickTesting || vm.quickProgress != null) ...[
              _buildQuickTestCard(context, l10n, isArabic, vm),
              const SizedBox(height: 16),
            ],

            // 5. Last speed test card
            _buildLastSpeedCard(context, l10n, isArabic, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context, AppLocalizations l10n, HomeViewModel vm) {
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
                const Icon(Icons.data_usage, color: MegaColors.warning),
                const SizedBox(width: 8),
                Text(
                  l10n.usageAccessRequired,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.usagePermissionRationale,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => vm.usageRepository.usageSource.openAccessSettings(),
                icon: const Icon(Icons.settings, size: 18),
                label: Text(l10n.usageOpenSettings),
                style: FilledButton.styleFrom(backgroundColor: MegaColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(
          children: [
            const Icon(Icons.wifi_tethering, size: 48, color: MegaColors.primary),
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => OnboardingSheet.show(context),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(l10n.bundleSetupTitle),
              style: FilledButton.styleFrom(
                backgroundColor: MegaColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    final todayMobileFormatted = ByteFormatter.format(vm.todayMobileBytes, isArabic: isArabic);
    final todayWifiFormatted = ByteFormatter.format(vm.todayWifiBytes, isArabic: isArabic);
    final safeDailyFormatted = ByteFormatter.format(vm.safeDailyAllowance, isArabic: isArabic);

    final usedPct = vm.usedPercentage;
    final isExpired = vm.isBundleExpired;

    Color progressColor = MegaColors.primary;
    if (usedPct >= 0.8) progressColor = MegaColors.warning;
    if (usedPct >= 1.0 || isExpired) progressColor = MegaColors.danger;

    final pace = vm.paceStatus;
    final paceText = isArabic ? pace.statusTextAr : pace.statusTextEn;

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Remaining label & Days Left badge
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
                    color: isExpired
                        ? MegaColors.danger.withValues(alpha: 0.15)
                        : MegaColors.primaryContainerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired ? l10n.homeBundleExpired : l10n.homeDaysLeft(vm.daysLeft),
                    style: TextStyle(
                      color: isExpired ? MegaColors.danger : MegaColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Large Number Hero
            if (isExpired) ...[
              Text(
                l10n.homeBundleExpired,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: MegaColors.danger,
                ),
              ),
            ] else ...[
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
            ],
            const SizedBox(height: 14),

            // Thin progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usedPct,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                color: progressColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),

            // Safe Daily Allowance & Pace Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    paceText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pace.willExceed ? MegaColors.warning : MegaColors.primary,
                    ),
                  ),
                ),
                Text(
                  l10n.homeSafeDailyAllowance(safeDailyFormatted),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Today's Usage numbers (Mobile and Wi-Fi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeTodayUsage(todayMobileFormatted, todayWifiFormatted),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${(usedPct * 100).toStringAsFixed(0)}% ($usedFormatted)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n, HomeViewModel vm) {
    return Row(
      children: [
        // Quick Test button
        Expanded(
          child: FilledButton.icon(
            onPressed: vm.isQuickTesting ? null : () => vm.runQuickTest(),
            icon: const Icon(Icons.flash_on, size: 20),
            label: Text(l10n.homeQuickTest),
            style: FilledButton.styleFrom(
              backgroundColor: MegaColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Renew Bundle button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRenewDialog(context, vm, l10n),
            icon: const Icon(Icons.autorenew, size: 20),
            label: Text(l10n.homeRenewBundle),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: MegaColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTestCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    HomeViewModel vm,
  ) {
    final progress = vm.quickProgress;
    if (progress == null) return const SizedBox.shrink();

    return Card(
      color: MegaColors.primaryContainerLight.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: MegaColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.homeQuickTest,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                if (vm.isQuickTesting)
                  TextButton(
                    onPressed: vm.cancelQuickTest,
                    child: Text(l10n.speedCancel),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (vm.isQuickTesting) ...[
              LinearProgressIndicator(
                value: progress.progressPercent,
                color: MegaColors.primary,
                backgroundColor: MegaColors.outlineLight,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  SpeedFormatter.formatMbps(progress.currentMbps, isArabic: isArabic),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: MegaColors.primary,
                  ),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(l10n.speedDownload, style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        SpeedFormatter.formatMbps(progress.downMbps, isArabic: isArabic),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MegaColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(l10n.speedUpload, style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        SpeedFormatter.formatMbps(progress.upMbps, isArabic: isArabic),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(l10n.speedPing, style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        SpeedFormatter.formatMs(progress.pingMs, isArabic: isArabic),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: MegaColors.primary,
                        ),
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
