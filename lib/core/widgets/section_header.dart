import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// The repeated "▍SECTION LABEL          [6]" header.
///
/// The green bar on the left is the app's most repeated motif — it marks every
/// section and every league line inside a match card.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.color = AppColors.green,
    this.labelColor,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 10),
  });

  final String label;

  /// Rendered as "[6]" on the right.
  final String? trailing;
  final Color color;
  final Color? labelColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          AccentBar(color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppText.sectionLabel.copyWith(color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              '[$trailing]',
              style: AppText.metaSmall.copyWith(color: AppColors.textFaint),
            ),
          ],
        ],
      ),
    );
  }
}

/// The 3x14 rounded green tick that prefixes headers and league names.
class AccentBar extends StatelessWidget {
  const AccentBar({super.key, this.color = AppColors.green, this.height = 14});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
