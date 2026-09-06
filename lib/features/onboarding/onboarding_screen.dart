import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../l10n/strings.dart';
import 'illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_PageSpec>[
    _PageSpec('ob_live_title', 'ob_live_body', LiveScoresArt()),
    _PageSpec('ob_lock_title', 'ob_lock_body', LockScreenArt()),
    _PageSpec('ob_alerts_title', 'ob_alerts_body', GoalAlertsArt()),
    _PageSpec('ob_widgets_title', 'ob_widgets_body', WidgetsArt()),
  ];

  bool get _isLast => _page == _pages.length - 1;

  void _next() {
    if (_isLast) {
      widget.onFinished();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final spec = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        spec.art,
                        const Spacer(),
                        Text(
                          s(spec.titleKey),
                          textAlign: TextAlign.center,
                          style: AppText.display,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s(spec.bodyKey),
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(fontSize: 16),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            _Dots(count: _pages.length, active: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: FilledButton(
                onPressed: _next,
                child: Text(s(_isLast ? 'get_started' : 'next')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageSpec {
  const _PageSpec(this.titleKey, this.bodyKey, this.art);
  final String titleKey;
  final String bodyKey;
  final Widget art;
}

/// Page indicator — the active dot stretches into a bar.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 26 : 8,
            height: 5,
            decoration: BoxDecoration(
              color: i == active ? AppColors.green : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
