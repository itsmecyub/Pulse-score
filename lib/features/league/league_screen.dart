import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/match_cards.dart';
import '../../core/widgets/team_crest.dart';
import '../../data/models/fixture.dart';
import '../../data/models/league_catalog.dart';
import '../../data/models/standing.dart';
import '../../data/repositories/football_repository.dart';
import '../../l10n/strings.dart';
import '../match/match_detail_screen.dart';

/// One league: its fixtures and its table.
class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key, required this.league, this.initialTab = 0});

  final CatalogLeague league;

  /// 0 = fixtures, 1 = standings. Lets a caller land straight on the table.
  final int initialTab;

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  List<Fixture> _fixtures = const [];
  List<Standing> _standings = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<FootballRepository>();
    final fixtures = await repo.fixturesForLeague(widget.league.id);
    final standings = await repo.standings(widget.league.id);
    if (!mounted) return;
    setState(() {
      _fixtures = List.of(fixtures.data)
        ..sort((a, b) => b.kickoff.compareTo(a.kickoff));
      _standings = standings.data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.league.name, style: AppText.heading),
            Text(
              '${widget.league.flag}  ${widget.league.code}',
              style: AppText.metaSmall,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.green,
          labelColor: AppColors.green,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppText.sectionLabel.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: s('schedule_title').toUpperCase()),
            Tab(text: s('standings')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _fixtures.isEmpty
                    ? EmptyMessage(
                        icon: Icons.event_busy_rounded,
                        title: s('no_fixtures'),
                        body: widget.league.name,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _fixtures.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => ScheduleRow(
                          fixture: _fixtures[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MatchDetailScreen(fixture: _fixtures[i]),
                            ),
                          ),
                        ),
                      ),
                _standings.isEmpty
                    ? EmptyMessage(
                        icon: Icons.table_chart_outlined,
                        title: s('standings'),
                        body: s('no_standings'),
                      )
                    : StandingsTable(rows: _standings),
              ],
            ),
    );
  }
}

/// League table. Horizontally scrollable so the stat columns never squeeze the
/// club name on a narrow phone.
class StandingsTable extends StatelessWidget {
  const StandingsTable({super.key, required this.rows});

  final List<Standing> rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        const _StandingsHeader(),
        for (final row in rows) _StandingsRow(row: row),
      ],
    );
  }
}

class _StandingsHeader extends StatelessWidget {
  const _StandingsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          const SizedBox(width: 26),
          const SizedBox(width: 34),
          const Expanded(child: SizedBox()),
          for (final label in ['P', 'W', 'D', 'L', 'GD', 'PTS'])
            SizedBox(
              width: label == 'PTS' ? 38 : 26,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.metaSmall.copyWith(color: AppColors.textFaint),
              ),
            ),
        ],
      ),
    );
  }
}

class _StandingsRow extends StatelessWidget {
  const _StandingsRow({required this.row});

  final Standing row;

  @override
  Widget build(BuildContext context) {
    // Top four get a green rank marker, bottom two red — the usual
    // promotion/relegation shorthand.
    final Color rankColor = row.rank <= 4
        ? AppColors.green
        : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${row.rank}',
              style: AppText.meta.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TeamCrest(team: row.team, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyStrong.copyWith(fontSize: 14.5),
            ),
          ),
          _Cell('${row.played}'),
          _Cell('${row.won}'),
          _Cell('${row.drawn}'),
          _Cell('${row.lost}'),
          _Cell(row.goalDifferenceLabel),
          SizedBox(
            width: 38,
            child: Text(
              '${row.points}',
              textAlign: TextAlign.center,
              style: AppText.meta.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: AppText.metaSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
