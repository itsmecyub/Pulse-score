import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'section_header.dart';

/// The boxed empty state used by Pinned and any list that can come back empty.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.sectionLabel,
    required this.tag,
    required this.title,
    required this.body,
    this.note,
    this.hint,
    this.mascot = true,
  });

  final String sectionLabel;

  /// The "[EMPTY]" pill on the right of the header.
  final String tag;
  final String title;
  final String body;
  final String? note;

  /// The bottom "→ do this next" line.
  final String? hint;
  final bool mascot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const AccentBar(height: 13),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  sectionLabel.toUpperCase(),
                  style: AppText.sectionLabel,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '[${tag.toUpperCase()}]',
                  style: AppText.metaSmall.copyWith(color: AppColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mascot) ...[
                const _PulseMascot(size: 72),
                const SizedBox(width: 18),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.heading.copyWith(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: AppText.meta.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 4),
                      Text(note!, style: AppText.meta.copyWith(fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    size: 13,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint!,
                    style: AppText.meta.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pulse, the app's dog mascot — a blocky green head. Drawn, not shipped.
class _PulseMascot extends StatelessWidget {
  const _PulseMascot({this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.green.withValues(alpha: 0.10),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.18),
            blurRadius: size * 0.3,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.62, size * 0.58),
          painter: _MascotPainter(),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = AppColors.green;
    final dark = Paint()..color = const Color(0xFF071409);

    // Ears, then a tapered muzzle-forward head.
    final ears = Path()
      ..moveTo(0, h * 0.10)
      ..lineTo(w * 0.20, h * 0.34)
      ..lineTo(0, h * 0.42)
      ..close()
      ..moveTo(w, h * 0.10)
      ..lineTo(w * 0.80, h * 0.34)
      ..lineTo(w, h * 0.42)
      ..close();
    canvas.drawPath(ears, fill);

    final head = Path()
      ..moveTo(w * 0.06, h * 0.20)
      ..lineTo(w * 0.94, h * 0.20)
      ..lineTo(w * 0.80, h)
      ..lineTo(w * 0.20, h)
      ..close();
    canvas.drawPath(head, fill);

    canvas.drawCircle(Offset(w * 0.33, h * 0.50), w * 0.055, dark);
    canvas.drawCircle(Offset(w * 0.67, h * 0.50), w * 0.055, dark);

    final nose = Path()
      ..moveTo(w * 0.44, h * 0.70)
      ..lineTo(w * 0.56, h * 0.70)
      ..lineTo(w * 0.50, h * 0.82)
      ..close();
    canvas.drawPath(nose, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple centred empty state for lists.
class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textFaint),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.heading.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: AppText.body),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
