import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app mark: a "P" crossed by an ECG pulse trace, with a ball riding the
/// tail of the line. Drawn rather than shipped as a bitmap so it stays sharp at
/// every size and can pick up the accent colour from the theme.
class PulseLogo extends StatelessWidget {
  const PulseLogo({super.key, this.size = 120, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14202F), Color(0xFF060A11)],
        ),
        border: Border.all(color: AppColors.green, width: size * 0.018),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.35),
                  blurRadius: size * 0.28,
                  spreadRadius: size * 0.01,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: CustomPaint(
          painter: _PulseMarkPainter(),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _PulseMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _paintP(canvas, w, h);
    _paintPulse(canvas, w, h);
    _paintBall(canvas, w, h);
  }

  void _paintP(Canvas canvas, double w, double h) {
    // A chunky slab "P": a vertical stem plus a bowl. Built as one path with
    // the counter subtracted, so the hole shows the gradient behind rather
    // than a flat patch — BlendMode.clear would need its own saveLayer and
    // would erase the container's gradient with it.
    final stem = Path()
      ..addRRect(RRect.fromLTRBR(
        w * 0.26,
        h * 0.20,
        w * 0.40,
        h * 0.74,
        Radius.circular(w * 0.02),
      ));

    final bowl = Path()
      ..addRRect(RRect.fromLTRBAndCorners(
        w * 0.38,
        h * 0.20,
        w * 0.68,
        h * 0.50,
        topRight: Radius.circular(w * 0.15),
        bottomRight: Radius.circular(w * 0.15),
      ));

    final counter = Path()
      ..addRRect(RRect.fromLTRBAndCorners(
        w * 0.40,
        h * 0.28,
        w * 0.60,
        h * 0.42,
        topRight: Radius.circular(w * 0.07),
        bottomRight: Radius.circular(w * 0.07),
      ));

    final solid = Path.combine(PathOperation.union, stem, bowl);
    final glyph = Path.combine(PathOperation.difference, solid, counter);
    canvas.drawPath(glyph, Paint()..color = Colors.white);
  }

  void _paintPulse(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.08, h * 0.60)
      ..lineTo(w * 0.24, h * 0.60)
      ..lineTo(w * 0.31, h * 0.44)
      ..lineTo(w * 0.40, h * 0.76)
      ..lineTo(w * 0.48, h * 0.60)
      ..lineTo(w * 0.92, h * 0.60);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.green;

    // Soft bloom under the trace, then the crisp line on top.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.green.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
    canvas.drawPath(path, stroke);
  }

  void _paintBall(Canvas canvas, double w, double h) {
    final centre = Offset(w * 0.70, h * 0.70);
    final r = w * 0.15;

    canvas.drawCircle(
      centre,
      r * 1.35,
      Paint()
        ..color = AppColors.green.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );
    canvas.drawCircle(centre, r, Paint()..color = Colors.white);

    // Classic panel pattern: a centre pentagon with spokes to the rim.
    final dark = Paint()..color = const Color(0xFF0B1220);
    final pentagon = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final p = centre + Offset(math.cos(a), math.sin(a)) * (r * 0.42);
      i == 0 ? pentagon.moveTo(p.dx, p.dy) : pentagon.lineTo(p.dx, p.dy);
    }
    pentagon.close();
    canvas.drawPath(pentagon, dark);

    final spoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0B1220);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(centre + dir * (r * 0.42), centre + dir * r, spoke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wordmark: "Pulse" in white, "Score" in green.
class PulseWordmark extends StatelessWidget {
  const PulseWordmark({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Pulse'),
          TextSpan(
            text: 'Score',
            style: const TextStyle(color: AppColors.green),
          ),
        ],
      ),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.1,
        color: Colors.white,
      ),
    );
  }
}
