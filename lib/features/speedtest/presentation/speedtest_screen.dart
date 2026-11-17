import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/format/speed.dart';
import '../../../l10n/app_localizations.dart';
import '../data/speed_test_engine.dart';
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

  void _confirmAndStart(BuildContext context, SpeedTestViewModel vm, AppLocalizations l10n) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: MegaColors.primary),
            const SizedBox(width: 8),
            Text(l10n.speedMobileWarningTitle, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          l10n.speedMobileWarningBody('15-25 MB'),
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
            child: Text(l10n.speedProceed),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        vm.startTest();
      }
    });
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
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          // Live Gauge / Hero Area
          _buildHeroGauge(context, l10n, isArabic, vm, progress),
          const SizedBox(height: 16),

          // 4 Metric Tiles: Ping, Jitter, Down, Up
          _buildMetricTiles(context, l10n, isArabic, progress),
          const SizedBox(height: 20),

          // History Section
          _buildHistorySection(context, l10n, isArabic, vm),
        ],
      ),
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
        padding: const EdgeInsetsDirectional.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            // Current phase indicator
            Text(
              _phaseLabel(progress.phase, l10n),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isRunning ? MegaColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
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
            const SizedBox(height: 20),

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
              const SizedBox(height: 20),
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
                onPressed: () => _confirmAndStart(context, vm, l10n),
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
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
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
                      '$dateStr · ${SpeedFormatter.formatMs(record.pingMs, isArabic: isArabic)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
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
