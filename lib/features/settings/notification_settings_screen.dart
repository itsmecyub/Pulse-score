import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';

/// Per-category notification toggles.
///
/// The master switch reflects the app's own preference. Actually registering
/// for push (and reading the OS-level permission) belongs to whichever push
/// SDK gets wired in — this screen is the surface it will drive.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final app = context.watch<AppState>();
    final on = app.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(s('notifications'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          SectionHeader(label: s('sec_notifications')),
          _Card(
            child: SwitchListTile.adaptive(
              value: on,
              onChanged: app.setNotificationsEnabled,
              activeThumbColor: AppColors.green,
              title: Text(
                s('notifications'),
                style: AppText.bodyStrong.copyWith(fontSize: 16.5),
              ),
              subtitle: Text(s('notif_body'), style: AppText.metaSmall),
            ),
          ),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                _Toggle(label: s('notif_b1'), enabled: on),
                const Divider(height: 1),
                _Toggle(label: s('notif_b2'), enabled: on),
                const Divider(height: 1),
                _Toggle(label: s('notif_b3'), enabled: on),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Sub-category switches follow the master toggle and grey out when it is off.
class _Toggle extends StatefulWidget {
  const _Toggle({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: widget.enabled && _value,
      onChanged:
          widget.enabled ? (v) => setState(() => _value = v) : null,
      activeThumbColor: AppColors.green,
      title: Text(
        widget.label,
        style: AppText.bodyStrong.copyWith(
          fontSize: 16,
          color: widget.enabled
              ? AppColors.textPrimary
              : AppColors.textTertiary,
        ),
      ),
    );
  }
}
