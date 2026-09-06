import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/strings.dart';
import '../explore/explore_screen.dart';
import '../live/live_screen.dart';
import '../pinned/pinned_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';

/// The five-tab container.
///
/// Tabs are kept alive in an IndexedStack so scroll position and loaded data
/// survive switching — the Live tab in particular should not refetch every time
/// you glance at Settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  /// Which tab to open on. Lets a notification or deep link land the user
  /// straight on, say, Pinned instead of always starting at Live.
  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _index,
        children: const [
          LiveScreen(),
          ScheduleScreen(),
          ExploreScreen(),
          PinnedScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _TabBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        labels: [
          s('tab_live'),
          s('tab_schedule'),
          s('tab_explore'),
          s('tab_pinned'),
          s('tab_settings'),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.index,
    required this.onChanged,
    required this.labels,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  static const _icons = [
    Icons.wifi_tethering_rounded,
    Icons.grid_view_rounded,
    Icons.explore_rounded,
    Icons.push_pin_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _TabItem(
                    icon: _icons[i],
                    label: labels[i],
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
