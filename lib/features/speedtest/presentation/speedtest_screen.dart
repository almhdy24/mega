import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/format/speed.dart';
import '../../../l10n/app_localizations.dart';
import '../data/speed_test_engine.dart';
import '../domain/speed_math.dart';
import '../domain/speed_server.dart';
import 'server_selector_sheet.dart';
import 'speed_history_chart.dart';
import 'speedtest_view_model.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpeedTestViewModel>().init();
    });
  }

  Future<void> _confirmAndStart(
    BuildContext context,
    SpeedTestViewModel vm,
    AppLocalizations l10n,
    bool isArabic,
  ) async {
    final netType = await vm.detectNetworkType();
    if (netType != 'mobile' || vm.settings.skipMobileWarning) {
      vm.startTest(networkType: netType);
      return;
    }

    if (!context.mounted) return;

    final estimatedSize = estimateDataUsage(vm.selectedMode, isArabic);

    var dontAskAgain = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: MegaColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.speedMobileWarningTitle, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.speedMobileWarningBody(estimatedSize),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setDialogState(() {
                  dontAskAgain = !dontAskAgain;
                });
              },
              child: Row(
                children: [
                  Checkbox(
                    value: dontAskAgain,
                    onChanged: (v) {
                      setDialogState(() {
                        dontAskAgain = v ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isArabic ? 'عدم السؤال مرة أخرى على بيانات الهاتف' : 'Don\'t ask again on mobile data',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: MegaColors.primary),
            child: Text(l10n.speedProceed),
          ),
        ],
      ),
    ),
    );

    if (confirmed == true) {
      if (dontAskAgain) {
        vm.settings.skipMobileWarning = true;
      }
      vm.startTest(networkType: netType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final vm = context.watch<SpeedTestViewModel>();
    final progress = vm.progress;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSpeedTest),
        actions: [
          IconButton(
            tooltip: l10n.speedServer,
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => ServerSelectorSheet.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          // Top Controls: Server Chip & Mode Toggle
          _buildControlsRow(context, vm, isArabic, l10n),
          const SizedBox(height: 12),

          // Live Gauge / Hero Area
          _buildHeroGauge(context, l10n, isArabic, vm, progress),
          const SizedBox(height: 16),

          // 4 Metric Tiles: Ping, Jitter (with stability), Down, Up
          _buildMetricTiles(context, l10n, isArabic, progress),
          const SizedBox(height: 20),

          // History Section
          _buildHistorySection(context, l10n, isArabic, vm),
        ],
      ),
    );
  }

  Widget _buildControlsRow(
    BuildContext context,
    SpeedTestViewModel vm,
    bool isArabic,
    AppLocalizations l10n,
  ) {
    final selectedServer = vm.selectedServer;
    final isRunning = vm.isRunning;

    return Row(
      children: [
        // Server Selector Chip
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isRunning ? null : () => ServerSelectorSheet.show(context),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns_outlined, size: 16, color: MegaColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedServer.localizedName(isArabic),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Mode Segmented Buttons: Quick (~4 MB) vs Full (~20 MB)
        SegmentedButton<SpeedTestMode>(
          segments: [
            ButtonSegment(
              value: SpeedTestMode.quick,
              label: Text(
                isArabic ? 'سريع' : 'Quick',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            ButtonSegment(
              value: SpeedTestMode.full,
              label: Text(
                isArabic ? 'كامل' : 'Full',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          selected: {vm.selectedMode},
          onSelectionChanged: isRunning
              ? null
              : (set) {
                  if (set.isNotEmpty) vm.setTestMode(set.first);
                },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroGauge(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    SpeedTestViewModel vm,
    SpeedTestProgress progress,
  ) {
    final isRunning = vm.isRunning;

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            // Current phase indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _phaseLabel(progress.phase, l10n),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isRunning ? MegaColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (progress.server != null && progress.phase == SpeedTestPhase.completed) ...[
                  const SizedBox(width: 8),
                  Text(
                    '· ${progress.server!.localizedName(isArabic)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Big Live Number
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  isRunning
                      ? progress.currentMbps.toStringAsFixed(1)
                      : (progress.phase == SpeedTestPhase.completed
                          ? progress.downMbps.toStringAsFixed(1)
                          : '0.0'),
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: MegaColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'ميجابت/ث' : 'Mbps',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            if (isRunning) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progressPercent > 0 ? progress.progressPercent : null,
                  backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  color: MegaColors.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            if (isRunning)
              OutlinedButton.icon(
                onPressed: () => vm.cancelTest(),
                icon: const Icon(Icons.stop, color: MegaColors.danger),
                label: Text(l10n.speedCancel, style: const TextStyle(color: MegaColors.danger)),
              )
            else
              FilledButton.icon(
                onPressed: () => _confirmAndStart(context, vm, l10n, isArabic),
                style: FilledButton.styleFrom(
                  backgroundColor: MegaColors.primary,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(
                  l10n.speedStart,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

            if (progress.phase == SpeedTestPhase.failed) ...[
              const SizedBox(height: 12),
              Text(
                l10n.speedFailed,
                style: const TextStyle(color: MegaColors.danger, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTiles(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    SpeedTestProgress progress,
  ) {
    String? stabilityLabel;
    Color? stabilityColor;
    if (progress.jitterMs > 0) {
      switch (progress.stability) {
        case SpeedStability.excellent:
          stabilityLabel = l10n.speedStabilityExcellent;
          stabilityColor = MegaColors.success;
          break;
        case SpeedStability.good:
          stabilityLabel = l10n.speedStabilityGood;
          stabilityColor = MegaColors.warning;
          break;
        case SpeedStability.unstable:
          stabilityLabel = l10n.speedStabilityUnstable;
          stabilityColor = MegaColors.danger;
          break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _metricTile(
            context,
            title: l10n.speedPing,
            value: progress.pingMs > 0 ? SpeedFormatter.formatMs(progress.pingMs, isArabic: isArabic) : '--',
            icon: Icons.alt_route,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricTile(
            context,
            title: l10n.speedJitter,
            value: progress.jitterMs > 0 ? SpeedFormatter.formatMs(progress.jitterMs, isArabic: isArabic) : '--',
            icon: Icons.waves,
            badge: stabilityLabel,
            badgeColor: stabilityColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricTile(
            context,
            title: l10n.speedDownload,
            value: progress.downMbps > 0 ? SpeedFormatter.formatMbps(progress.downMbps, isArabic: isArabic) : '--',
            icon: Icons.arrow_downward,
            highlightColor: MegaColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricTile(
            context,
            title: l10n.speedUpload,
            value: progress.upMbps > 0 ? SpeedFormatter.formatMbps(progress.upMbps, isArabic: isArabic) : '--',
            icon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? highlightColor,
    String? badge,
    Color? badgeColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(10),
        child: Column(
          children: [
            Icon(icon, size: 18, color: highlightColor ?? Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor?.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    SpeedTestViewModel vm,
  ) {
    final history = vm.history;

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.speedHistory,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    l10n.speedNoHistory,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else ...[
              SpeedHistoryChart(records: history),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length > 5 ? 5 : history.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final record = history[i];
                  final dateStr = DateFormat.yMMMd(isArabic ? 'ar' : 'en')
                      .add_jm()
                      .format(DateTime.fromMillisecondsSinceEpoch(record.ts));

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 18,
                      backgroundColor: MegaColors.primaryContainerLight,
                      child: Icon(Icons.speed, size: 18, color: MegaColors.primary),
                    ),
                    title: Text(
                      '${SpeedFormatter.formatMbps(record.downMbps, isArabic: isArabic)} ↓  ${SpeedFormatter.formatMbps(record.upMbps, isArabic: isArabic)} ↑',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '$dateStr · ${SpeedFormatter.formatMs(record.pingMs, isArabic: isArabic)} · ${record.server}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _phaseLabel(SpeedTestPhase phase, AppLocalizations l10n) {
    switch (phase) {
      case SpeedTestPhase.pinging:
        return '${l10n.speedPing}...';
      case SpeedTestPhase.downloading:
        return '${l10n.speedDownload}...';
      case SpeedTestPhase.uploading:
        return '${l10n.speedUpload}...';
      case SpeedTestPhase.completed:
        return l10n.speedHistory;
      case SpeedTestPhase.failed:
        return l10n.speedFailed;
      case SpeedTestPhase.cancelled:
        return l10n.speedCancel;
      case SpeedTestPhase.idle:
        return l10n.appName;
    }
  }
}
