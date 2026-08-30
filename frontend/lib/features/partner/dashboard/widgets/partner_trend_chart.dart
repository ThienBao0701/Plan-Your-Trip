import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/partner/partner_dashboard_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_spacing.dart';

/// A compact time-series chart for the partner dashboard.
///
/// Hand-painted rather than pulled from a charting package: the app has no
/// charting dependency and adding one for two panels would be a large surface
/// for a small need. `CustomPainter` also keeps the whole thing inside the
/// Ocean Glass tokens.
///
/// The only client-side arithmetic here is axis scaling — mapping a value onto
/// a pixel. No business figure is derived, smoothed, interpolated or projected;
/// every plotted point is a `TimeSeriesPoint` the backend computed.
///
/// Degenerate inputs are all handled explicitly, because real partner data hits
/// every one of them:
///   * **no points** — the caller renders an empty state instead; this widget
///     also refuses to paint rather than dividing by a zero range.
///   * **all zeros** — a flat baseline, not a divide-by-zero and not a
///     misleading auto-zoomed line.
///   * **a single point** — drawn as a dot, since a one-point line has no slope.
///   * **partial periods** — fewer points simply means a shorter series; the
///     axis follows the data, never a padded window that implies missing days
///     were zero.
///
/// Accessibility: the chart is never the only way to read the data. It exposes
/// a [Semantics] summary, and [PartnerTrendChart] is always rendered alongside
/// the caller's textual figures.
class PartnerTrendChart extends StatelessWidget {
  final List<PartnerTimeSeriesPoint> points;

  /// Line/area colour. Defaults to the ocean accent.
  final Color color;

  /// Formats a value for the axis label and the semantic summary.
  final String Function(double value) formatValue;

  /// Formats a date for the axis labels and the semantic summary.
  final String Function(DateTime date) formatDate;

  /// Spoken description, e.g. "Revenue per day".
  final String semanticLabel;

  final double height;

  const PartnerTrendChart({
    super.key,
    required this.points,
    required this.formatValue,
    required this.formatDate,
    required this.semanticLabel,
    this.color = AppColors.ocean600,
    this.height = 168,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final values = points.map((p) => p.value).toList(growable: false);
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final first = points.first;
    final last = points.last;

    // A flat all-zero (or all-equal) series is a real answer, not an error:
    // paint it on the baseline rather than auto-zooming a meaningless range.
    final isFlat = maxValue == minValue;

    return Semantics(
      label: semanticLabel,
      value: _summary(maxValue, minValue),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatValue(maxValue),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!isFlat)
                  Text(
                    formatValue(minValue),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (context, constraints) => CustomPaint(
                  size: Size(constraints.maxWidth, height),
                  painter: _TrendPainter(
                    points: points,
                    maxValue: maxValue,
                    minValue: minValue,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(first.date),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
                if (points.length > 1)
                  Text(
                    formatDate(last.date),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _summary(double maxValue, double minValue) {
    final last = points.last;
    return '${points.length} points, '
        '${formatDate(points.first.date)} to ${formatDate(last.date)}. '
        'High ${formatValue(maxValue)}, low ${formatValue(minValue)}, '
        'latest ${formatValue(last.value)}.';
  }
}

class _TrendPainter extends CustomPainter {
  final List<PartnerTimeSeriesPoint> points;
  final double maxValue;
  final double minValue;
  final Color color;

  _TrendPainter({
    required this.points,
    required this.maxValue,
    required this.minValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const inset = 6.0;
    final chartHeight = math.max(size.height - inset * 2, 1.0);

    // Baseline at zero when the data is non-negative, so a bar of value 0 sits
    // on the floor instead of floating mid-chart.
    final lowerBound = math.min(minValue, 0.0);
    final range = maxValue - lowerBound;

    double yFor(double value) {
      if (range <= 0) return inset + chartHeight; // flat series → baseline
      final normalized = (value - lowerBound) / range;
      return inset + chartHeight - (normalized * chartHeight);
    }

    double xFor(int index) {
      if (points.length == 1) return size.width / 2;
      return (index / (points.length - 1)) * size.width;
    }

    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = inset + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // A single point has no line to draw — mark it and stop.
    if (points.length == 1) {
      canvas.drawCircle(
        Offset(xFor(0), yFor(points.first.value)),
        4,
        Paint()..color = color,
      );
      return;
    }

    final linePath = Path();
    final areaPath = Path()..moveTo(0, inset + chartHeight);
    for (var i = 0; i < points.length; i++) {
      final offset = Offset(xFor(i), yFor(points[i].value));
      if (i == 0) {
        linePath.moveTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
      }
      areaPath.lineTo(offset.dx, offset.dy);
    }
    areaPath
      ..lineTo(size.width, inset + chartHeight)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.02)
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Emphasise the most recent reading — the one an operator acts on.
    final lastOffset = Offset(xFor(points.length - 1), yFor(points.last.value));
    canvas
      ..drawCircle(lastOffset, 4.5, Paint()..color = AppColors.white)
      ..drawCircle(
        lastOffset,
        4.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.minValue != minValue ||
      oldDelegate.color != color;
}
