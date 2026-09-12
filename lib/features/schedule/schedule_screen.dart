import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/match_cards.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/fixture.dart';
import '../../data/models/league_catalog.dart';
import '../../data/repositories/football_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../match/match_detail_screen.dart';
import '../premium/paywall_screen.dart';

/// Fixtures and results for one league at a time.
///
/// The league strip leads with the user's default league, then the rest of the
/// catalog; premium-only competitions show a padlock and route to the paywall
/// rather than loading.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with AutomaticKeepAliveClientMixin {
  int? _leagueId;
  List<Fixture> _fixtures = const [];
  bool _loading = true;
  String? _notice;
  bool _serviceEmpty = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _select(context.read<AppState>().defaultLeagueId);
    });
  }

  Future<void> _select(int leagueId, {bool force = false}) async {
    setState(() {
      _leagueId = leagueId;
      _loading = true;
    });

    final result =
        await context.read<FootballRepository>().fixturesForLeague(leagueId, force: force);
    if (!mounted || _leagueId != leagueId) return;

    setState(() {
      _fixtures = List.of(result.data)
        ..sort((a, b) => b.kickoff.compareTo(a.kickoff));
      _notice = result.notice;
      _serviceEmpty =
          context.read<FootballRepository>().backendHasNoData;
      _loading = false;
    });
  }

  /// Default league first, then everything else in catalog order.
  List<CatalogLeague> _orderedLeagues(int defaultId) {
    final all = LeagueCatalog.all;
    final first = all.where((l) => l.id == defaultId);
    return [...first, ...all.where((l) => l.id != defaultId)];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.strings;
    final app = context.watch<AppState>();
    final leagues = _orderedLeagues(app.defaultLeagueId);
    final selected = LeagueCatalog.byId(_leagueId ?? app.defaultLeagueId);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(s('schedule_title'), style: AppText.title),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leagues.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final league = leagues[i];
                final locked = !app.canAccess(league);
                return _LeagueChip(
                  league: league,
                  locked: locked,
                  selected: league.id == _leagueId,
                  onTap: () {
                    if (locked) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      );
                    } else {
                      _select(league.id);
                    }
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _fixtures.isEmpty
                    ? EmptyMessage(
                        icon: _serviceEmpty
                            ? Icons.cloud_off_rounded
                            : Icons.event_busy_rounded,
                        // "No fixtures for this league" is wrong when the
                        // backend is serving nothing at all — the league may
                        // well be playing; we just have no data for anyone.
                        title: _serviceEmpty
                            ? s('service_no_data')
                            : s('no_fixtures'),
                        body: selected == null
                            ? ''
                            : '${selected.name} · ${selected.code}',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _fixtures.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == 0) return _header(selected);
                          final fixture = _fixtures[i - 1];
                          return ScheduleRow(
                            fixture: fixture,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MatchDetailScreen(fixture: fixture),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _notice!,
                style: AppText.metaSmall.copyWith(color: AppColors.amber),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(CatalogLeague? league) {
    if (league == null) return const SizedBox.shrink();
    final round = _fixtures.first.league.roundLabel;
    return SectionHeader(
      label: '${_fixtures.first.league.name}  ·  ${league.code}',
      trailing: round,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
    );
  }
}

class _LeagueChip extends StatelessWidget {
  const _LeagueChip({
    required this.league,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  final CatalogLeague league;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.green.withValues(alpha: 0.10)
                : AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              if (locked) ...[
                const Icon(Icons.lock_rounded,
                    size: 13, color: AppColors.green),
                const SizedBox(width: 7),
              ],
              Text(
                league.name,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 15,
                  color:
                      selected ? AppColors.textPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                league.code,
                style: AppText.metaSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
