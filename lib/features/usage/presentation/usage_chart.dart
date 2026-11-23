import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/format/bytes.dart';
import '../domain/daily_usage.dart';

class UsageBarChart extends StatelessWidget {
  final List<DailyUsage> data;
  final bool isArabic;

  const UsageBarChart({
    super.key,
    required this.data,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: Text(
          isArabic ? 'لا توجد بيانات كافية للرسم البياني' : 'No usage data available',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _UsageChartPainter(
          data: data,
          mobileColor: MegaColors.primary,
          wifiColor: isDark ? MegaColors.accent.withValues(alpha: 0.8) : MegaColors.primaryLight.withValues(alpha: 0.7),
          gridColor: isDark ? MegaColors.outlineDark : MegaColors.outlineLight,
          textColor: isDark ? MegaColors.textMutedDark : MegaColors.textMutedLight,
          isArabic: isArabic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  final List<DailyUsage> data;
  final Color mobileColor;
  final Color wifiColor;
  final Color gridColor;
  final Color textColor;
  final bool isArabic;

  _UsageChartPainter({
    required this.data,
    required this.mobileColor,
    required this.wifiColor,
    required this.gridColor,
    required this.textColor,
    required this.isArabic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 8.0;
    const rightPadding = 8.0;
    const bottomPadding = 24.0;
    const topPadding = 20.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Find max usage across days
    int maxBytes = 0;
    for (final d in data) {
      final total = d.mobileTotal + d.wifiTotal;
      if (total > maxBytes) maxBytes = total;
    }

    if (maxBytes == 0) maxBytes = 100 * 1024 * 1024; // 100 MB default ceiling

    // Draw baseline
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final baselineY = size.height - bottomPadding;
    canvas.drawLine(
      Offset(leftPadding, baselineY),
      Offset(size.width - rightPadding, baselineY),
      gridPaint,
    );

    // Max guide label
    final maxFormatted = ByteFormatter.format(maxBytes, isArabic: isArabic);
    final textPainter = TextPainter(
      text: TextSpan(
        text: maxFormatted,
        style: TextStyle(color: textColor, fontSize: 10),
      ),
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(leftPadding, topPadding - 16));

    // Draw mid line
    final midY = topPadding + (chartHeight / 2);
    final midPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(leftPadding, midY),
      Offset(size.width - rightPadding, midY),
      midPaint,
    );

    // Bars
    final count = data.length;
    final totalBarWidth = chartWidth / count;
    final barWidth = max(2.0, totalBarWidth * 0.65);

    final mobilePaint = Paint()..color = mobileColor;
    final wifiPaint = Paint()..color = wifiColor;

    for (var i = 0; i < count; i++) {
      final item = data[i];
      final x = leftPadding + (i * totalBarWidth) + (totalBarWidth - barWidth) / 2;

      final mobileHeight = (item.mobileTotal / maxBytes) * chartHeight;
      final wifiHeight = (item.wifiTotal / maxBytes) * chartHeight;

      // Draw mobile bar (bottom layer)
      if (mobileHeight > 0) {
        final mobileRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, baselineY - mobileHeight, barWidth, mobileHeight),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        );
        canvas.drawRRect(mobileRect, mobilePaint);
      }

      // Draw wifi bar (stacked on top of mobile)
      if (wifiHeight > 0) {
        final wifiRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, baselineY - mobileHeight - wifiHeight, barWidth, wifiHeight),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        );
        canvas.drawRRect(wifiRect, wifiPaint);
      }

      // Draw date labels for first day, last day, and intermediate 7-day intervals
      // Avoid interval labels too close (< 4 days) to start or end boundaries to prevent collision
      final isBoundary = (i == 0 || i == count - 1);
      final isInterval = (i % 7 == 0 && i >= 4 && (count - 1 - i) >= 4);
      if (isBoundary || isInterval) {
        final dayParts = item.day.split('-');
        final dayLabel = dayParts.length == 3 ? '${dayParts[1]}/${dayParts[2]}' : item.day;

        final labelPainter = TextPainter(
          text: TextSpan(
            text: dayLabel,
            style: TextStyle(color: textColor, fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelX = (x + barWidth / 2 - labelPainter.width / 2)
            .clamp(leftPadding, size.width - rightPadding - labelPainter.width);
        labelPainter.paint(canvas, Offset(labelX, baselineY + 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.mobileColor != mobileColor ||
        oldDelegate.wifiColor != wifiColor ||
        oldDelegate.gridColor != gridColor;
  }
}
