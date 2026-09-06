import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The breathing red dot next to anything in play.
///
/// Kept as its own widget so exactly one animation controller drives each dot
/// and it stops with the widget — a list of 38 live matches would otherwise be
/// 38 unmanaged tickers.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.size = 8, this.color = AppColors.live});

  final double size;
  final Color color;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: widget.size,
            ),
          ],
        ),
      ),
    );
  }
}
