import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_locales.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';

/// First-run language picker, also reachable from Settings.
///
/// Selection is applied immediately so the header retitles itself in the
/// chosen language — the confirm tick just closes the screen.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.isFirstRun = false, this.onDone});

  final bool isFirstRun;
  final VoidCallback? onDone;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selected = context.read<AppState>().languageCode;

  void _choose(String code) {
    setState(() => _selected = code);
    context.read<AppState>().setLanguage(code);
  }

  void _confirm() {
    context.read<AppState>().setLanguage(_selected);
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: s('language_title'),
              subtitle: s('language_subtitle'),
              showBack: !widget.isFirstRun,
              onConfirm: _confirm,
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: kSupportedLocales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final option = kSupportedLocales[i];
                  return _LanguageRow(
                    option: option,
                    selected: option.code == _selected,
                    onTap: () => _choose(option.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.onConfirm,
  });

  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            child: showBack
                ? IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, style: AppText.title, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_rounded, size: 26),
              color: AppColors.green,
              tooltip: 'Confirm',
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppLocaleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.green.withValues(alpha: 0.10)
                : AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text(option.flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.nativeName,
                      style: AppText.heading.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 2),
                    Text(option.englishName, style: AppText.meta),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
