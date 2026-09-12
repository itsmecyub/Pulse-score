import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/league_catalog.dart';
import '../../l10n/app_locales.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../language/language_screen.dart';
import '../premium/paywall_screen.dart';
import 'notification_settings_screen.dart';

/// App version shown in the footer. Kept in step with `version:` in pubspec.
const kAppVersion = 'v1.1.6';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final app = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(s('settings_title'), style: AppText.title),
            ),
          ),

          SectionHeader(label: s('sec_premium')),
          _Group(
            children: [
              SettingsRow(
                icon: Icons.workspace_premium_rounded,
                label: app.isPremium
                    ? s('premium_active')
                    : s('upgrade_premium'),
                trailing: app.isPremium
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.green, size: 20)
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
              ),
            ],
          ),

          SectionHeader(label: s('sec_display')),
          _Group(
            children: [
              SettingsRow(
                icon: Icons.language_rounded,
                label: s('language'),
                value: localeOptionFor(app.languageCode).nativeName,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
              ),
            ],
          ),

          SectionHeader(label: s('sec_content')),
          _Group(
            children: [
              SettingsRow(
                icon: Icons.emoji_events_rounded,
                label: s('default_league'),
                value: app.defaultLeague.name,
                onTap: () => _pickLeague(context, app),
              ),
            ],
          ),

          SectionHeader(label: s('sec_notifications')),
          _Group(
            children: [
              SettingsRow(
                icon: Icons.notifications_rounded,
                label: s('notifications'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),

          SectionHeader(label: s('sec_legal')),
          _Group(
            children: [
              SettingsRow(
                icon: Icons.lock_rounded,
                label: s('privacy_policy'),
                external: true,
                onTap: () => _openLegal('privacy', app.languageCode),
              ),
              const _Rule(),
              SettingsRow(
                icon: Icons.description_rounded,
                label: s('terms'),
                external: true,
                onTap: () => _openLegal('terms', app.languageCode),
              ),
            ],
          ),

          SectionHeader(label: s('sec_support')),
          _Group(
            children: [
              SettingsRow(
                icon: Icons.star_rounded,
                label: s('rate_app'),
                onTap: () => _open(
                  'https://apps.apple.com/app/id0000000000?action=write-review',
                ),
              ),
            ],
          ),

          const SizedBox(height: 34),
          Center(
            child: Column(
              children: [
                Text(
                  'PULSESCORE',
                  style: AppText.sectionLabel.copyWith(
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kAppVersion,
                  style: AppText.meta.copyWith(color: AppColors.textFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// Opens a legal page in the language the app is currently set to, so a
  /// reader is not dropped into English after choosing Vietnamese.
  static Future<void> _openLegal(String doc, String languageCode) => launchUrl(
        ApiConfig.legalUri(doc, languageCode),
        mode: LaunchMode.externalApplication,
      );

  Future<void> _pickLeague(BuildContext context, AppState app) async {
    final s = context.strings;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SectionHeader(label: s('default_league')),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final league in LeagueCatalog.all)
                    ListTile(
                      leading: Text(
                        league.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        league.name,
                        style: AppText.bodyStrong.copyWith(fontSize: 16),
                      ),
                      subtitle: Text(league.country, style: AppText.metaSmall),
                      trailing: league.id == app.defaultLeagueId
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.green)
                          : null,
                      onTap: () => Navigator.of(context).pop(league.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null) await app.setDefaultLeague(picked);
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

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
      child: Column(children: children),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.only(left: 62), child: Divider());
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.external = false,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Right-aligned current value, e.g. "English".
  final String? value;
  final Widget? trailing;

  /// Shows the "opens outside the app" glyph instead of a chevron.
  final bool external;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 19, color: AppColors.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.bodyStrong.copyWith(fontSize: 16.5),
              ),
            ),
            if (value != null) ...[
              // Flexible as well as the label: on a 320pt screen a long value
              // ("Premier League") would otherwise push the row over its width
              // however far the label had already shrunk.
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta,
                ),
              ),
              const SizedBox(width: 8),
            ],
            trailing ??
                Icon(
                  external
                      ? Icons.open_in_new_rounded
                      : Icons.chevron_right_rounded,
                  size: external ? 17 : 22,
                  color: AppColors.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}
