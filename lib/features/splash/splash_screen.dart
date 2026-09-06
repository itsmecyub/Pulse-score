import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/pulse_logo.dart';

/// First frame after launch. Deliberately static — it exists to cover the gap
/// while preferences load, not to entertain.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      // Center, not a bare Column: inside the launch crossfade this screen is
      // handed *loose* width constraints, and a Column under those shrink-wraps
      // to its widest child and hugs the left edge instead of centring.
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Spacer(flex: 3),
              const PulseLogo(size: 128),
              const SizedBox(height: 26),
              const PulseWordmark(fontSize: 40),
              const SizedBox(height: 12),
              Text(
                'Live Football Scores & Stats',
                style: AppText.body.copyWith(fontSize: 16),
              ),
              const Spacer(flex: 3),
              const _Spinner(),
              const SizedBox(height: 16),
              Text(message, style: AppText.meta.copyWith(letterSpacing: 1.6)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A ring with a solid core that breathes — a heartbeat rather than a spinner.
class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.green.withValues(alpha: 0.25 + 0.35 * t),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 12 + 3 * t,
              height: 12 + 3 * t,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.5 * t),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
