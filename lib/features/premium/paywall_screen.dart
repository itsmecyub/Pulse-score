import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pulse_logo.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';

/// Premium upsell.
///
/// The entitlement is a local flag: there is no store integration yet, so
/// "unlock" simply grants it. Dropping in RevenueCat or in_app_purchase means
/// replacing [_unlock] and the restore handler — nothing else on this screen
/// or in [AppState.isPremium] has to change.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              const PulseLogo(size: 92),
              const SizedBox(height: 22),
              Text(
                s('premium_title'),
                textAlign: TextAlign.center,
                style: AppText.display.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 12),
              Text(
                s('premium_body'),
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  children: [
                    _Feature(label: s('premium_f1')),
                    const SizedBox(height: 14),
                    _Feature(label: s('premium_f2')),
                    const SizedBox(height: 14),
                    _Feature(label: s('premium_f3')),
                    const SizedBox(height: 14),
                    _Feature(label: s('premium_f4')),
                  ],
                ),
              ),
              const Spacer(),
              if (app.isPremium)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppColors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.green, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        s('premium_active'),
                        style: AppText.button.copyWith(
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                )
              else
                FilledButton(
                  onPressed: () => app.setPremium(true),
                  child: Text(s('premium_cta')),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => app.setPremium(true),
                child: Text(s('premium_restore')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.green, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: AppText.bodyStrong.copyWith(fontSize: 16)),
        ),
      ],
    );
  }
}
