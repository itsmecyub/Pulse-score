import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// The pre-permission screen.
///
/// It deliberately does *not* trigger the OS prompt on its own — iOS only lets
/// you ask once, so this explains the value first and only then hands off. The
/// actual `requestPermission` call lives behind [onEnable] so wiring up a push
/// SDK later is a one-line change.
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({
    super.key,
    required this.onEnable,
    required this.onSkip,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: 0.12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      size: 52,
                      color: AppColors.green,
                    ),
                    Positioned(
                      top: 30,
                      right: 30,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: AppColors.greenBright,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(
                '[${s('notif_kicker')}]',
                style: AppText.sectionLabel.copyWith(color: AppColors.green),
              ),
              const SizedBox(height: 14),
              Text(
                s('notif_title'),
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                s('notif_body'),
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Column(
                  children: [
                    _Bullet(
                      icon: Icons.event_available_rounded,
                      label: s('notif_b1'),
                    ),
                    const SizedBox(height: 18),
                    _Bullet(
                      icon: Icons.sports_soccer_rounded,
                      label: s('notif_b2'),
                    ),
                    const SizedBox(height: 18),
                    _Bullet(
                      icon: Icons.sports_score_rounded,
                      label: s('notif_b3'),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: onEnable,
                child: Text(s('notif_enable')),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: onSkip,
                child: Text(s('notif_later')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.green, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppText.bodyStrong.copyWith(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
