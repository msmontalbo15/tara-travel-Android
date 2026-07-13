import 'package:flutter/material.dart';

/// CustomPainter that draws the dark navigation map background
/// matching the Tara Travel mockup style.
class MockMapPainter extends CustomPainter {
  final bool showRoute;
  final bool showProximityRings;
  final double animationValue; // 0–1, used for animated route dash

  const MockMapPainter({
    this.showRoute = true,
    this.showProximityRings = false,
    this.animationValue = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Background ───────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF35404F),
    );

    // Water bottom-right
    final waterPath = Path()
      ..moveTo(w, h * 0.76)
      ..quadraticBezierTo(w * 0.55, h * 0.7, w * 0.55, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(waterPath, Paint()..color = const Color(0xFF1E2D3D));

    // ── Roads ────────────────────────────────────────────────
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round;

    // Horizontal
    _drawRoad(canvas, Offset(0, h * 0.16), Offset(w, h * 0.16), 4, roadPaint);
    _drawRoad(canvas, Offset(0, h * 0.28), Offset(w, h * 0.28), 2.5, roadPaint..color = Colors.white.withValues(alpha: 0.10));
    _drawRoad(canvas, Offset(0, h * 0.40), Offset(w, h * 0.40), 5.5, roadPaint..color = Colors.white.withValues(alpha: 0.18));
    _drawRoad(canvas, Offset(0, h * 0.56), Offset(w, h * 0.56), 2.5, roadPaint..color = Colors.white.withValues(alpha: 0.10));
    _drawRoad(canvas, Offset(0, h * 0.68), Offset(w, h * 0.68), 4, roadPaint..color = Colors.white.withValues(alpha: 0.18));

    // Vertical
    _drawRoad(canvas, Offset(w * 0.18, 0), Offset(w * 0.18, h), 2.5, roadPaint..color = Colors.white.withValues(alpha: 0.10));
    _drawRoad(canvas, Offset(w * 0.35, 0), Offset(w * 0.35, h), 4.5, roadPaint..color = Colors.white.withValues(alpha: 0.18));
    _drawRoad(canvas, Offset(w * 0.59, 0), Offset(w * 0.59, h), 3.5, roadPaint..color = Colors.white.withValues(alpha: 0.14));
    _drawRoad(canvas, Offset(w * 0.76, 0), Offset(w * 0.76, h), 6.5, roadPaint..color = Colors.white.withValues(alpha: 0.18));

    // ── Building blocks ──────────────────────────────────────
    final blockPaint1 = Paint()..color = const Color(0xFF3A4658);
    final blockPaint2 = Paint()..color = const Color(0xFF4A5568);

    _drawBlock(canvas, w*0.15, h*0.18, w*0.17, h*0.08, blockPaint1);
    _drawBlock(canvas, w*0.38, h*0.18, w*0.18, h*0.08, blockPaint1);
    _drawBlock(canvas, w*0.62, h*0.18, w*0.11, h*0.08, blockPaint2);
    _drawBlock(canvas, w*0.38, h*0.30, w*0.17, h*0.076, blockPaint1);
    _drawBlock(canvas, w*0.62, h*0.30, w*0.11, h*0.076, blockPaint2);
    _drawBlock(canvas, w*0.15, h*0.42, w*0.17, h*0.115, blockPaint1);
    _drawBlock(canvas, w*0.38, h*0.42, w*0.17, h*0.115, blockPaint2);
    _drawBlock(canvas, w*0.62, h*0.42, w*0.11, h*0.115, blockPaint1);
    _drawBlock(canvas, w*0.15, h*0.58, w*0.17, h*0.076, blockPaint1);
    _drawBlock(canvas, w*0.38, h*0.70, w*0.11, h*0.115, blockPaint1);

    if (showProximityRings) {
      _drawProximityRings(canvas, size);
    } else if (showRoute) {
      _drawRoute(canvas, size);
    }
  }

  void _drawRoad(Canvas canvas, Offset a, Offset b, double width, Paint paint) {
    canvas.drawLine(a, b, paint..strokeWidth = width);
  }

  void _drawBlock(Canvas canvas, double x, double y, double w, double h, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      paint,
    );
  }

  void _drawRoute(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final routePath = Path()
      ..moveTo(w * 0.50, h * 0.96)
      ..lineTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.76, h * 0.68)
      ..lineTo(w * 0.76, h * 0.40)
      ..lineTo(w * 0.50, h * 0.40)
      ..lineTo(w * 0.50, h * 0.10);

    // Shadow
    canvas.drawPath(
      routePath,
      Paint()
        ..color = const Color(0xFF992B10)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Main route
    canvas.drawPath(
      routePath,
      Paint()
        ..color = const Color(0xFFD85A30)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // White dashes overlay (uses animationValue for future animation)
    canvas.drawPath(
      routePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawProximityRings(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFFD85A30));
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      40,
      Paint()..color = const Color(0xFFD85A30).withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      center,
      40,
      Paint()
        ..color = const Color(0xFFD85A30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawDashedCircle(canvas, center, 90, const Color(0xFFD85A30).withValues(alpha: 0.5));

    canvas.drawLine(
      Offset(center.dx, size.height * 0.88),
      center,
      Paint()
        ..color = const Color(0xFFD85A30)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Color color) {
    const dashCount = 24;
    const dashAngle = 0.18;
    const gap = (2 * 3.14159 / dashCount) - dashAngle;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gap);
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          dashAngle,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(MockMapPainter old) =>
      old.animationValue != animationValue ||
      old.showRoute != showRoute ||
      old.showProximityRings != showProximityRings;
}
