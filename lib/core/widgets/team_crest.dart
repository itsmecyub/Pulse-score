import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/team.dart';
import '../theme/app_colors.dart';

/// A team badge that always renders something.
///
/// Crest URLs are missing for plenty of lower-division sides, and demo mode has
/// none at all, so the fallback (initials on a tinted disc) is the common case
/// rather than an edge case — it has to look deliberate.
class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, required this.team, this.size = 40});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: team.logo == null
          ? _Initials(team: team, size: size)
          : Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: CachedNetworkImage(
                imageUrl: team.logo!,
                fit: BoxFit.contain,
                placeholder: (_, _) => _Initials(team: team, size: size),
                errorWidget: (_, _, _) => _Initials(team: team, size: size),
              ),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.team, required this.size});

  final Team team;
  final double size;

  /// Derive a stable hue from the team id so a given club always gets the same
  /// colour, rather than the badges flickering between rebuilds.
  Color get _tint {
    const palette = [
      Color(0xFF2BE06B),
      Color(0xFF3D8BFD),
      Color(0xFFFFB020),
      Color(0xFFFF6B6B),
      Color(0xFF9B7DFF),
      Color(0xFF25C2C2),
    ];
    return palette[team.id.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tint;
    return Container(
      alignment: Alignment.center,
      color: tint.withValues(alpha: 0.14),
      child: Text(
        team.initials,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: tint,
          height: 1,
        ),
      ),
    );
  }
}
