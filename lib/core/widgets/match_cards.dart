import 'package:flutter/material.dart';

import '../../data/models/fixture.dart';
import '../../data/models/team.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'live_dot.dart';
import 'section_header.dart';
import 'team_crest.dart';

/// Shared chrome for the two full-width cards. Live matches get a red-tinted
/// wash and border, upcoming favourites a green one; everything else is the
/// same shell.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    required this.accent,
    required this.onTap,
  });

  final Widget child;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: accent.withValues(alpha: 0.55)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.10),
                accent.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Full-width card used by the featured carousel and the live carousel.
class MatchCardLarge extends StatelessWidget {
  const MatchCardLarge({
    super.key,
    required this.fixture,
    this.onTap,
    this.starred = false,
  });

  final Fixture fixture;
  final VoidCallback? onTap;

  /// Shows the green star, marking a followed match.
  final bool starred;

  @override
  Widget build(BuildContext context) {
    final live = fixture.isLive;
    final accent = live ? AppColors.live : AppColors.green;

    return _CardShell(
      accent: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, live, accent),
          const SizedBox(height: 12),
          _TeamLine(
            team: fixture.home,
            goals: fixture.homeGoals,
            showGoals: !fixture.isUpcoming,
            dimmed: _isLosing(home: true),
          ),
          const SizedBox(height: 10),
          _TeamLine(
            team: fixture.away,
            goals: fixture.awayGoals,
            showGoals: !fixture.isUpcoming,
            dimmed: _isLosing(home: false),
          ),
          const SizedBox(height: 14),
          _footer(context),
        ],
      ),
    );
  }

  /// Fade the side that is behind, so a glance at the card reads the result.
  bool _isLosing({required bool home}) {
    if (!fixture.hasScore) return false;
    final h = fixture.homeGoals!;
    final a = fixture.awayGoals!;
    if (h == a) return false;
    return home ? h < a : a < h;
  }

  Widget _header(BuildContext context, bool live, Color accent) {
    return Row(
      children: [
        if (live) ...[
          const LiveDot(),
          const SizedBox(width: 8),
          // One Text, not two: on a narrow card (the peeking carousel item, or
          // a small phone) two side-by-side unbounded labels overflow, whereas
          // a single rich span ellipsizes the tail cleanly.
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'LIVE NOW'),
                  TextSpan(
                    text: "  ·  ${fixture.status.badge} minute",
                    style: AppText.clock.copyWith(
                      color: accent.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.clock.copyWith(color: accent),
            ),
          ),
        ] else ...[
          if (starred) ...[
            const Icon(Icons.star_rounded, size: 18, color: AppColors.green),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              countdown(fixture.timeUntilKickoff),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.clock.copyWith(color: accent),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          size: 22,
          color: AppColors.textSecondary.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final round = fixture.league.roundLabel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: AccentBar(height: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            round == null
                ? fixture.league.name.toUpperCase()
                : '${fixture.league.name.toUpperCase()}  ·  $round',
            style: AppText.metaSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (fixture.isUpcoming) ...[
          const SizedBox(width: 10),
          Text(
            kickoffStamp(fixture.kickoff),
            style: AppText.metaSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.team,
    required this.goals,
    required this.showGoals,
    required this.dimmed,
  });

  final Team team;
  final int? goals;
  final bool showGoals;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamCrest(team: team, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            team.name,
            style: AppText.teamName.copyWith(
              color: dimmed ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showGoals) ...[
          const SizedBox(width: 10),
          Text(
            '${goals ?? 0}',
            style: AppText.score.copyWith(
              color: dimmed ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact tile for the two-column "FEATURED · TODAY" grid.
class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.fixture, this.onTap});

  final Fixture fixture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final live = fixture.isLive;
    final accent = live ? AppColors.live : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: live ? accent.withValues(alpha: 0.5) : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (live) ...[
                    const LiveDot(size: 6),
                    const SizedBox(width: 6),
                    Text(
                      fixture.status.badge,
                      style: AppText.metaSmall.copyWith(
                        color: AppColors.live,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else
                    Text(
                      fixture.isUpcoming
                          ? hhmm(fixture.kickoff)
                          : fixture.status.badge,
                      style: AppText.metaSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _CompactTeamRow(
                team: fixture.home,
                goals: fixture.homeGoals,
                showGoals: !fixture.isUpcoming,
              ),
              const SizedBox(height: 8),
              _CompactTeamRow(
                team: fixture.away,
                goals: fixture.awayGoals,
                showGoals: !fixture.isUpcoming,
              ),
              const SizedBox(height: 10),
              Text(
                fixture.league.name.toUpperCase(),
                style: AppText.metaSmall.copyWith(color: AppColors.textFaint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTeamRow extends StatelessWidget {
  const _CompactTeamRow({
    required this.team,
    required this.goals,
    required this.showGoals,
  });

  final Team team;
  final int? goals;
  final bool showGoals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamCrest(team: team, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team.name,
            style: AppText.bodyStrong.copyWith(fontSize: 13.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showGoals)
          Text(
            '${goals ?? 0}',
            style: AppText.scoreSmall.copyWith(
              fontSize: 15,
              color: (goals ?? 0) > 0 ? AppColors.green : AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}

/// A row in the Schedule tab: status on the left, both sides stacked, scores
/// hard-right.
class ScheduleRow extends StatelessWidget {
  const ScheduleRow({super.key, required this.fixture, this.onTap});

  final Fixture fixture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final homeWon = (fixture.homeGoals ?? 0) > (fixture.awayGoals ?? 0);
    final awayWon = (fixture.awayGoals ?? 0) > (fixture.homeGoals ?? 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fixture.isLive) ...[
                      Row(
                        children: [
                          const LiveDot(size: 6),
                          const SizedBox(width: 5),
                          Text(
                            fixture.status.badge,
                            style: AppText.metaSmall.copyWith(
                              color: AppColors.live,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        fixture.isUpcoming
                            ? hhmm(fixture.kickoff)
                            : fixture.status.badge,
                        style: AppText.meta.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      fixture.isUpcoming
                          ? dayMonth(fixture.kickoff).split(' ').take(2).join(' ')
                          : ago(fixture.kickoff),
                      style: AppText.metaSmall.copyWith(
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _ScheduleTeamRow(
                      team: fixture.home,
                      goals: fixture.homeGoals,
                      showGoals: !fixture.isUpcoming,
                      highlight: homeWon,
                    ),
                    const SizedBox(height: 12),
                    _ScheduleTeamRow(
                      team: fixture.away,
                      goals: fixture.awayGoals,
                      showGoals: !fixture.isUpcoming,
                      highlight: awayWon,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleTeamRow extends StatelessWidget {
  const _ScheduleTeamRow({
    required this.team,
    required this.goals,
    required this.showGoals,
    required this.highlight,
  });

  final Team team;
  final int? goals;
  final bool showGoals;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamCrest(team: team, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            team.name,
            style: AppText.teamName.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showGoals)
          Text(
            '${goals ?? 0}',
            style: AppText.scoreSmall.copyWith(
              color: highlight ? AppColors.green : AppColors.textPrimary,
            ),
          ),
      ],
    );
  }
}
