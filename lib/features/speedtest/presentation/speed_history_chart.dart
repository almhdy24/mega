import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../domain/speed_test_record.dart';

class SpeedHistoryChart extends StatelessWidget {
  final List<SpeedTestRecord> records;

  const SpeedHistoryChart({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.length < 2) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _SpeedChartPainter(
          records: records.reversed.toList(), // Chronological
          downColor: MegaColors.primary,
          upColor: isDark ? MegaColors.accent : MegaColors.primaryLight,
          gridColor: isDark ? MegaColors.outlineDark : MegaColors.outlineLight,
          textColor: isDark ? MegaColors.textMutedDark : MegaColors.textMutedLight,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SpeedChartPainter extends CustomPainter {
  final List<SpeedTestRecord> records;
  final Color downColor;
  final Color upColor;
  final Color gridColor;
  final Color textColor;

  _SpeedChartPainter({
    required this.records,
    required this.downColor,
    required this.upColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 16.0;
    const bottomPad = 16.0;

    final w = size.width - leftPad - rightPad;
    final h = size.height - topPad - bottomPad;
    if (w <= 0 || h <= 0 || records.isEmpty) return;

    double maxMbps = 10.0;
    for (final r in records) {
      if (r.downMbps > maxMbps) maxMbps = r.downMbps;
      if (r.upMbps > maxMbps) maxMbps = r.upMbps;
    }

    // Grid baseline
    final baselineY = size.height - bottomPad;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(leftPad, baselineY), Offset(size.width - rightPad, baselineY), gridPaint);

    final stepX = w / max(1, records.length - 1);

    final downPath = Path();
    final upPath = Path();

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final x = leftPad + (i * stepX);
      final downY = baselineY - (r.downMbps / maxMbps * h);
      final upY = baselineY - (r.upMbps / maxMbps * h);

      if (i == 0) {
        downPath.moveTo(x, downY);
        upPath.moveTo(x, upY);
      } else {
        downPath.lineTo(x, downY);
        upPath.lineTo(x, upY);
      }
    }

    final downPaint = Paint()
      ..color = downColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final upPaint = Paint()
      ..color = upColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(downPath, downPaint);
    canvas.drawPath(upPath, upPaint);

    // Draw dots
    final dotPaintDown = Paint()..color = downColor;
    final dotPaintUp = Paint()..color = upColor;
    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final x = leftPad + (i * stepX);
      final downY = baselineY - (r.downMbps / maxMbps * h);
      final upY = baselineY - (r.upMbps / maxMbps * h);

      canvas.drawCircle(Offset(x, downY), 3.0, dotPaintDown);
      canvas.drawCircle(Offset(x, upY), 2.5, dotPaintUp);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedChartPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.downColor != downColor ||
        oldDelegate.upColor != upColor;
  }
}
