import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/league_catalog.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../league/league_screen.dart';
import '../premium/paywall_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CatalogLeague> _filter(List<CatalogLeague> source) {
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return source
        .where((l) =>
            l.name.toLowerCase().contains(q) ||
            l.country.toLowerCase().contains(q) ||
            l.code.toLowerCase().contains(q))
        .toList();
  }

  void _open(CatalogLeague league) {
    final app = context.read<AppState>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => app.canAccess(league)
            ? LeagueScreen(league: league)
            : const PaywallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.strings;
    final app = context.watch<AppState>();

    final top = _filter(LeagueCatalog.top);
    final more = _filter(LeagueCatalog.more);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(s('explore_title'), style: AppText.title),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SearchField(
                hint: s('search_hint'),
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
          ),
          if (top.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeader(label: s('top_leagues'))),
            _grid(top, app, highlight: true),
          ],
          if (more.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeader(label: s('more_leagues'))),
            _grid(more, app, highlight: false),
          ],
          SliverToBoxAdapter(child: SectionHeader(label: s('news'))),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: _NewsCard(
                title: s('latest_headlines'),
                subtitle: s('news_sub'),
                locked: !app.isPremium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(
    List<CatalogLeague> leagues,
    AppState app, {
    required bool highlight,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 76,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _LeagueCard(
            league: leagues[i],
            highlight: highlight,
            locked: !app.canAccess(leagues[i]),
            onTap: () => _open(leagues[i]),
          ),
          childCount: leagues.length,
        ),
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  const _LeagueCard({
    required this.league,
    required this.highlight,
    required this.locked,
    required this.onTap,
  });

  final CatalogLeague league;
  final bool highlight;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: highlight
                  ? AppColors.green.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _LeagueBadge(league: league),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 14pt, not 15: at 15 the longest names in the catalog
                    // ("Championship", "Premiership") are a hair wider than the
                    // column and break mid-word.
                    Text(
                      league.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          league.flag,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          league.code,
                          style: AppText.metaSmall.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                size: locked ? 15 : 20,
                color: locked ? AppColors.green : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// League crest from the API's media CDN, falling back to the country flag.
class _LeagueBadge extends StatelessWidget {
  const _LeagueBadge({required this.league});

  final CatalogLeague league;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: CachedNetworkImage(
          imageUrl:
              'https://media.api-sports.io/football/leagues/${league.id}.png',
          fit: BoxFit.contain,
          placeholder: (_, _) => _flag(),
          errorWidget: (_, _, _) => _flag(),
        ),
      ),
    );
  }

  Widget _flag() => Center(
        child: Text(league.flag, style: const TextStyle(fontSize: 20)),
      );
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.title,
    required this.subtitle,
    required this.locked,
  });

  final String title;
  final String subtitle;
  final bool locked;

  static final _feed = Uri.parse('https://www.bbc.com/sport/football');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (locked) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            );
          } else {
            launchUrl(_feed, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.heading.copyWith(fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppText.meta),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_rounded : Icons.open_in_new_rounded,
                size: 17,
                color: AppColors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
