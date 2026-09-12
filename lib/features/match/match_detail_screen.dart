import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/live_dot.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/team_crest.dart';
import '../../data/models/fixture.dart';
import '../../data/models/match_event.dart';
import '../../data/repositories/football_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../ads/navigation_ad_helper.dart';
import '../premium/paywall_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key, required this.fixture});

  final Fixture fixture;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late Fixture _fixture = widget.fixture;
  List<MatchEvent> _events = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Opening a match counts as a meaningful tap: every second one shows an
    // interstitial.
    maybeShowInterstitialAd();
  }

  Future<void> _load() async {
    final repo = context.read<FootballRepository>();
    final events = await repo.eventsFor(_fixture.id);
    // A live match's score may have moved since the list was rendered.
    final refreshed = _fixture.isLive
        ? await repo.fixtureById(_fixture.id)
        : null;

    if (!mounted) return;
    setState(() {
      _events = List.of(events.data)
        ..sort((a, b) => a.minute.compareTo(b.minute));
      if (refreshed?.data != null) _fixture = refreshed!.data!;
      _loading = false;
    });
  }

  Future<void> _togglePin() async {
    final app = context.read<AppState>();
    final ok = await app.toggleMatchPin(_fixture.id);
    if (!mounted) return;
    if (!ok) {
      // The free tier's pin cap is the whole reason Premium exists — send them
      // there rather than silently refusing.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final app = context.watch<AppState>();
    final pinned = app.isMatchPinned(_fixture.id);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_fixture.league.name, style: AppText.heading),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: _togglePin,
              icon: Icon(
                pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                size: 17,
                color: pinned ? AppColors.green : AppColors.textSecondary,
              ),
              label: Text(
                s(pinned ? 'unpin' : 'pin'),
                style: AppText.metaSmall.copyWith(
                  color: pinned ? AppColors.green : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Scoreboard(fixture: _fixture),
          SectionHeader(label: s('match_events')),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_events.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(s('no_events'), style: AppText.body),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final event in _events)
                    _EventRow(event: event, fixture: _fixture),
                ],
              ),
            ),
          SectionHeader(label: s('match_info')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: s('kickoff'),
                    value: kickoffStamp(_fixture.kickoff),
                  ),
                  if (_fixture.venue?.label != null)
                    _InfoRow(
                      label: s('venue'),
                      value: _fixture.venue!.label!,
                    ),
                  if (_fixture.referee != null)
                    _InfoRow(label: s('referee'), value: _fixture.referee!),
                  if (_fixture.halftimeHome != null &&
                      _fixture.halftimeAway != null)
                    _InfoRow(
                      label: s('half_time'),
                      value:
                          '${_fixture.halftimeHome} - ${_fixture.halftimeAway}',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    final live = fixture.isLive;
    final accent = live ? AppColors.live : AppColors.green;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (live) ...[
                const LiveDot(size: 7),
                const SizedBox(width: 8),
              ],
              Text(
                live
                    ? "${fixture.status.badge}  ·  ${fixture.status.long}"
                    : fixture.isUpcoming
                        ? countdown(fixture.timeUntilKickoff)
                        : fixture.status.long,
                style: AppText.clock.copyWith(color: accent, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Side(fixture: fixture, home: true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  fixture.hasScore
                      ? '${fixture.homeGoals} - ${fixture.awayGoals}'
                      : hhmm(fixture.kickoff),
                  style: AppText.score.copyWith(
                    fontSize: fixture.hasScore ? 38 : 26,
                  ),
                ),
              ),
              Expanded(child: _Side(fixture: fixture, home: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.fixture, required this.home});

  final Fixture fixture;
  final bool home;

  @override
  Widget build(BuildContext context) {
    final team = home ? fixture.home : fixture.away;
    return Column(
      children: [
        TeamCrest(team: team, size: 58),
        const SizedBox(height: 10),
        Text(
          team.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.bodyStrong.copyWith(fontSize: 15),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.fixture});

  final MatchEvent event;
  final Fixture fixture;

  ({IconData icon, Color color}) get _glyph => switch (event.kind) {
        EventKind.goal ||
        EventKind.penalty =>
          (icon: Icons.sports_soccer_rounded, color: AppColors.green),
        EventKind.ownGoal =>
          (icon: Icons.sports_soccer_rounded, color: AppColors.live),
        EventKind.penaltyMissed =>
          (icon: Icons.block_rounded, color: AppColors.live),
        EventKind.yellow =>
          (icon: Icons.square_rounded, color: AppColors.amber),
        EventKind.red => (icon: Icons.square_rounded, color: AppColors.live),
        EventKind.subst =>
          (icon: Icons.swap_horiz_rounded, color: AppColors.textSecondary),
        _ => (icon: Icons.circle, color: AppColors.textTertiary),
      };

  @override
  Widget build(BuildContext context) {
    final glyph = _glyph;
    final isHome = event.teamId == fixture.home.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              event.minuteLabel,
              style: AppText.meta.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(glyph.icon, size: 16, color: glyph.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.player ?? event.teamName,
                  style: AppText.bodyStrong.copyWith(fontSize: 15),
                ),
                if (event.assist != null)
                  Text(
                    event.assist!,
                    style: AppText.metaSmall.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            isHome ? fixture.home.initials : fixture.away.initials,
            style: AppText.metaSmall.copyWith(color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppText.body.copyWith(fontSize: 14.5)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.meta.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
