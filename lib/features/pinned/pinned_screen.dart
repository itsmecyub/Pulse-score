import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/match_cards.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/fixture.dart';
import '../../data/repositories/football_repository.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../match/match_detail_screen.dart';

/// Matches involving the teams and games the user follows.
class PinnedScreen extends StatefulWidget {
  const PinnedScreen({super.key});

  @override
  State<PinnedScreen> createState() => _PinnedScreenState();
}

class _PinnedScreenState extends State<PinnedScreen>
    with AutomaticKeepAliveClientMixin {
  List<Fixture> _fixtures = const [];
  bool _loading = false;
  Set<int> _loadedFor = const {};

  @override
  bool get wantKeepAlive => true;

  /// Refetch only when the pinned set actually changed, not on every rebuild.
  Future<void> _syncIfNeeded(Set<int> teamIds) async {
    if (setEquals(_loadedFor, teamIds)) return;
    _loadedFor = Set.of(teamIds);

    if (teamIds.isEmpty) {
      setState(() => _fixtures = const []);
      return;
    }

    setState(() => _loading = true);
    final repo = context.read<FootballRepository>();
    final collected = <int, Fixture>{};
    for (final id in teamIds) {
      final result = await repo.fixturesForTeam(id);
      for (final f in result.data) {
        collected[f.id] = f;
      }
    }
    if (!mounted) return;
    setState(() {
      _fixtures = collected.values.toList()
        ..sort((a, b) {
          // Live first, then soonest kickoff.
          if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
          return a.kickoff.compareTo(b.kickoff);
        });
      _loading = false;
    });
  }

  static bool setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.every(b.contains);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.strings;
    final app = context.watch<AppState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncIfNeeded(app.pinnedTeamIds);
    });

    final hasPins =
        app.pinnedTeamIds.isNotEmpty || app.pinnedMatchIds.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(s('pinned_title'), style: AppText.title),
          ),
          Expanded(
            child: !hasPins
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: EmptyStateCard(
                        sectionLabel: s('pinned_status'),
                        tag: s('empty_tag'),
                        title: s('no_pinned_title'),
                        body: s('no_pinned_body'),
                        note: s('no_pinned_note'),
                        hint: s('no_pinned_hint'),
                      ),
                    ),
                  )
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _fixtures.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return SectionHeader(
                              label: s('pinned_status'),
                              trailing: '${_fixtures.length}',
                              padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                            );
                          }
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
          if (hasPins && _fixtures.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s('no_fixtures'),
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 4),
          if (!app.isPremium && hasPins)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '${app.pinnedTeamIds.length}/${AppState.freePinLimit}',
                style: AppText.metaSmall.copyWith(color: AppColors.textFaint),
              ),
            ),
        ],
      ),
    );
  }
}
