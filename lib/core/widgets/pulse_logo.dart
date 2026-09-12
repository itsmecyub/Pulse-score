import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app mark, shown from the same artwork as the launcher icon so the
/// splash and the home screen agree.
///
/// The file carries its own dark ground and green frame, and has no alpha —
/// the rounded clip trims the square corners that would otherwise sit as black
/// notches on the navy background.
class PulseLogo extends StatelessWidget {
  const PulseLogo({super.key, this.size = 120, this.glow = true});

  static const asset = 'assets/icon/app_icon.png';

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.235);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
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
        borderRadius: radius,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
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
