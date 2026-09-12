import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/live_dot.dart';
import '../../core/widgets/match_cards.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/fixture.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../state/matches_state.dart';
import '../match/match_detail_screen.dart';
import '../premium/paywall_screen.dart';

enum _Filter { all, live, favorites }

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _search = TextEditingController();
  final _featuredPage = PageController(viewportFraction: 0.94);

  /// Held as a field, not built inline: the tab re-renders on every poll, and
  /// a fresh controller each time would leak and snap the carousel back to the
  /// first card mid-scroll.
  final _livePage = PageController(viewportFraction: 0.88);

  _Filter _filter = _Filter.all;
  String _query = '';
  int _featuredIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matches = context.read<MatchesState>();
      // The splash already ran the first fetch, so only load here if it hasn't
      // happened — otherwise a cold start would hit the metered API twice.
      if (matches.status == LoadStatus.idle) matches.load();
      matches.startPolling();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Polling a metered API from the background is pure waste — and iOS will
    // suspend the timer anyway, so resume with a fresh fetch instead.
    final matches = context.read<MatchesState>();
    if (state == AppLifecycleState.resumed) {
      // Coming back to the app should show current scores, not whatever was
      // cached before it was backgrounded.
      matches.load(silent: true, force: true);
      matches.startPolling();
    } else {
      matches.stopPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    _featuredPage.dispose();
    _livePage.dispose();
    super.dispose();
  }

  void _openMatch(Fixture f) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MatchDetailScreen(fixture: f)),
    );
  }

  List<Fixture> _visibleLive(MatchesState matches, AppState app) {
    final base = switch (_filter) {
      _Filter.all => matches.live,
      _Filter.live => matches.live,
      _Filter.favorites =>
        matches.favourites(app.pinnedTeamIds, app.pinnedMatchIds),
    };
    return _applyQuery(base);
  }

  List<Fixture> _applyQuery(List<Fixture> source) {
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return source
        .where((f) =>
            f.home.name.toLowerCase().contains(q) ||
            f.away.name.toLowerCase().contains(q) ||
            f.league.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.strings;
    final app = context.watch<AppState>();
    final matches = context.watch<MatchesState>();

    final live = _visibleLive(matches, app);
    final featuredGrid = _applyQuery(
      [...matches.live, ...matches.featured],
    ).take(6).toList();
    final upcoming = matches.featured;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: matches.refresh,
        color: AppColors.green,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopBar(matches: matches)),
            if (matches.notice != null)
              SliverToBoxAdapter(child: _Notice(text: matches.notice!)),

            // Featured upcoming carousel.
            if (_filter == _Filter.all &&
                _query.isEmpty &&
                upcoming.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 196,
                  child: PageView.builder(
                    controller: _featuredPage,
                    itemCount: upcoming.length,
                    onPageChanged: (i) => setState(() => _featuredIndex = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: MatchCardLarge(
                        fixture: upcoming[i],
                        starred: true,
                        onTap: () => _openMatch(upcoming[i]),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _Dots(count: upcoming.length, active: _featuredIndex),
              ),
            ],

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: SearchField(
                  hint: s('search_hint'),
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilterChips(
                  labels: [s('f_all'), s('f_live'), s('f_favorites')],
                  index: _Filter.values.indexOf(_filter),
                  onChanged: (i) =>
                      setState(() => _filter = _Filter.values[i]),
                ),
              ),
            ),

            if (matches.isFirstLoad)
              const SliverToBoxAdapter(child: _LoadingRows())
            else ...[
              // Live carousel.
              if (live.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                    child: Row(
                      children: [
                        const LiveDot(size: 9),
                        const SizedBox(width: 9),
                        Text(
                          '${s('live_now')}  ·  ${live.length}',
                          style: AppText.sectionLabel.copyWith(
                            color: AppColors.live,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 214,
                    child: PageView.builder(
                      controller: _livePage,
                      padEnds: false,
                      itemCount: live.length,
                      itemBuilder: (context, i) => Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 16 : 6,
                          right: 6,
                        ),
                        child: MatchCardLarge(
                          fixture: live[i],
                          onTap: () => _openMatch(live[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: EmptyMessage(
                    icon: _filter == _Filter.favorites
                        ? Icons.push_pin_outlined
                        : matches.backendHasNoData
                            ? Icons.cloud_off_rounded
                            : Icons.sports_soccer_outlined,
                    title: _filter == _Filter.favorites
                        ? s('no_pinned_title')
                        : matches.backendHasNoData
                            ? s('service_no_data')
                            : s('no_live_title'),
                    // When the backend is serving nothing, "nothing is live
                    // right now" would be a guess we cannot actually make.
                    body: _filter == _Filter.favorites
                        ? s('no_pinned_body')
                        : matches.backendHasNoData
                            ? ''
                            : s('no_live_body'),
                  ),
                ),

              // Featured grid.
              if (_filter == _Filter.all && featuredGrid.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    label: s('featured_today'),
                    trailing: '${featuredGrid.length}',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 156,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => MatchTile(
                        fixture: featuredGrid[i],
                        onTap: () => _openMatch(featuredGrid[i]),
                      ),
                      childCount: featuredGrid.length,
                    ),
                  ),
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.matches});

  final MatchesState matches;

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremium;

    final updated = matches.backendLastUpdated ?? matches.lastUpdated;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          // Proof the app is actually talking to the backend, and how current
          // what you are looking at is.
          if (updated != null)
            Expanded(
              child: Text(
                _freshness(updated),
                style: AppText.metaSmall.copyWith(color: AppColors.textFaint),
              ),
            )
          else
            const Spacer(),
          _RoundButton(
            icon: Icons.refresh_rounded,
            color: AppColors.green,
            onTap: matches.refresh,
          ),
          const SizedBox(width: 10),
          _RoundButton(
            icon: isPremium
                ? Icons.workspace_premium_rounded
                : Icons.workspace_premium_outlined,
            color: AppColors.green,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// "UPDATED JUST NOW" / "UPDATED 4M AGO" — `ago()` returns "now" under a
/// minute, which would otherwise read as "updated now ago".
String _freshness(DateTime at) {
  final label = ago(at);
  return label == 'now' ? 'UPDATED JUST NOW' : 'UPDATED ${label.toUpperCase()} AGO';
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppText.metaSmall.copyWith(color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == active ? 22 : 7,
              height: 4,
              decoration: BoxDecoration(
                color: i == active ? AppColors.green : AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton placeholders for the first load.
class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
