import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'review_prompter.dart';

/// Wraps the main screen and offers the App Store review dialog once.
///
/// A wrapper rather than logic inside [HomeShell] so the shell stays about
/// tabs, and so the trigger point is obvious: this is mounted only when the
/// user has actually reached the app, never during the splash or first run.
class ReviewPromptHost extends StatefulWidget {
  const ReviewPromptHost({
    super.key,
    required this.child,
    this.prompter = const ReviewPrompter(),
  });

  final Widget child;

  /// Injectable for tests.
  final ReviewPrompter prompter;

  @override
  State<ReviewPromptHost> createState() => _ReviewPromptHostState();
}

class _ReviewPromptHostState extends State<ReviewPromptHost> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // After the first frame, then a beat longer: the ask should land on a
    // screen with scores on it, not over the loading state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer(ReviewPrompter.settleDelay, () {
        if (!mounted) return;
        widget.prompter.maybePrompt(context.read<AppState>());
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
