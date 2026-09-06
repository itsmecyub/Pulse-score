import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// The four onboarding illustrations.
///
/// Composed from primitives rather than shipped as PNGs: they stay sharp at
/// every screen density, follow the accent colour, and cost a few KB instead of
/// a few megabytes of raster art.

const _phoneBody = Color(0xFF060A11);
const _phoneEdge = Color(0xFF2C3A4E);
const _chipFill = Color(0xFF0E1826);

/// Shared art board: the rounded, softly-lit panel each illustration sits in.
class ArtBoard extends StatelessWidget {
  const ArtBoard({super.key, required this.child, this.badge});

  final Widget child;

  /// The small circular glyph tucked into the bottom-right corner.
  final IconData? badge;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.02,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          gradient: const RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.0,
            colors: [Color(0xFF13202F), Color(0xFF0A111C)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.10),
              blurRadius: 40,
              spreadRadius: -6,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: child),
            if (badge != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Icon(badge, color: AppColors.green, size: 24),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A stylised handset used by the first two illustrations.
class _Phone extends StatelessWidget {
  const _Phone({required this.width, this.child, this.island = false});

  final double width;
  final Widget? child;

  /// Draws the Dynamic Island pill instead of the plain camera notch.
  final bool island;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 2.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.16),
        color: _phoneBody,
        border: Border.all(color: _phoneEdge, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (child != null) Positioned.fill(child: child!),
          Positioned(
            top: width * 0.05,
            child: Container(
              width: island ? width * 0.42 : width * 0.30,
              height: width * 0.11,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(width * 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A floating "LV 3 - 1 MU · 84' LIVE" score chip.
class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.home,
    required this.away,
    required this.score,
    required this.minute,
    this.scale = 1.0,
  });

  final String home;
  final String away;
  final String score;
  final String minute;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: _chipFill,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.22),
            blurRadius: 18 * scale,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pip(label: home, scale: scale),
              SizedBox(width: 7 * scale),
              Text(
                score,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              SizedBox(width: 7 * scale),
              _Pip(label: away, scale: scale),
            ],
          ),
          SizedBox(height: 5 * scale),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4 * scale,
                height: 4 * scale,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4 * scale),
              Text(
                "$minute  LIVE",
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 8 * scale,
                  color: AppColors.green,
                  letterSpacing: 0.6,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.label, this.scale = 1.0});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20 * scale,
      height: 20 * scale,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF16202E),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 8 * scale,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// Page 1 — floating live score chips around a handset.
class LiveScoresArt extends StatelessWidget {
  const LiveScoresArt({super.key});

  @override
  Widget build(BuildContext context) {
    return ArtBoard(
      badge: Icons.wifi_tethering_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.05),
                child: _Phone(
                  width: w * 0.34,
                  island: true,
                  child: Padding(
                    padding: EdgeInsets.only(top: w * 0.30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LIVE SCORES.\nREAL-TIME THRILLS.',
                          textAlign: TextAlign.center,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: w * 0.037,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: w * 0.02),
                        Text(
                          'Stay updated with every goal,\nminute by minute.',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            fontSize: w * 0.025,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: w * 0.05),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.05,
                            vertical: w * 0.022,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppColors.green.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Text(
                            'START TRACKING',
                            style: AppText.metaSmall.copyWith(
                              color: AppColors.green,
                              fontSize: w * 0.024,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * 0.04,
                top: w * 0.16,
                child: _ScoreChip(
                  home: 'LV',
                  away: 'MU',
                  score: '3 - 1',
                  minute: "84'",
                  scale: w / 300,
                ),
              ),
              Positioned(
                right: w * 0.04,
                top: w * 0.38,
                child: _ScoreChip(
                  home: 'AR',
                  away: 'CH',
                  score: '2 - 1',
                  minute: "81'",
                  scale: w / 300,
                ),
              ),
              Positioned(
                left: w * 0.02,
                top: w * 0.60,
                child: _ScoreChip(
                  home: 'PS',
                  away: 'RM',
                  score: '1 - 1',
                  minute: "68'",
                  scale: w / 300,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Page 2 — a Lock Screen showing a live score in the island and a widget.
class LockScreenArt extends StatelessWidget {
  const LockScreenArt({super.key});

  @override
  Widget build(BuildContext context) {
    return ArtBoard(
      badge: Icons.mobile_friendly_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Rays behind the handset.
              Container(
                width: w * 0.8,
                height: w * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.green.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              _Phone(
                width: w * 0.40,
                island: true,
                child: Stack(
                  children: [
                    // Wallpaper.
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1B2A45), Color(0xFF0B1220)],
                          ),
                        ),
                      ),
                    ),
                    // Score inside the Dynamic Island.
                    Positioned(
                      top: w * 0.028,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: w * 0.22,
                          height: w * 0.045,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(w * 0.03),
                          ),
                          child: Text(
                            "2:1  67'",
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: w * 0.024,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Live Activity card.
                    Positioned(
                      left: w * 0.03,
                      right: w * 0.03,
                      bottom: w * 0.20,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: w * 0.028),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(w * 0.035),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'ABK',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: w * 0.022,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(width: w * 0.02),
                                Text(
                                  '2:1',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: w * 0.05,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(width: w * 0.02),
                                Text(
                                  'MFR',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: w * 0.022,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: w * 0.012),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: w * 0.018,
                                fontWeight: FontWeight.w700,
                                color: AppColors.live,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Torch / camera affordances.
                    Positioned(
                      left: w * 0.06,
                      bottom: w * 0.08,
                      child: Icon(
                        Icons.flashlight_on_rounded,
                        size: w * 0.035,
                        color: Colors.white54,
                      ),
                    ),
                    Positioned(
                      right: w * 0.06,
                      bottom: w * 0.08,
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: w * 0.035,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Page 3 — a bell surrounded by notification bubbles.
class GoalAlertsArt extends StatelessWidget {
  const GoalAlertsArt({super.key});

  @override
  Widget build(BuildContext context) {
    return ArtBoard(
      badge: Icons.notifications_active_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            children: [
              Positioned(
                top: w * 0.07,
                left: 0,
                right: 0,
                child: Text(
                  'Football App\nNotifications & Alerts',
                  textAlign: TextAlign.center,
                  style: AppText.heading.copyWith(fontSize: w * 0.062),
                ),
              ),
              Positioned(
                left: w * 0.05,
                top: w * 0.28,
                child: _Bubble(
                  icon: Icons.shield_rounded,
                  title: 'Match Reminder',
                  subtitle: '15:00',
                  scale: w / 320,
                ),
              ),
              Positioned(
                right: w * 0.05,
                top: w * 0.36,
                child: _Bubble(
                  icon: Icons.sports_soccer_rounded,
                  title: 'Kickoff:',
                  subtitle: 'Team A vs Team B · 21:00',
                  scale: w / 320,
                ),
              ),
              Positioned(
                left: w * 0.04,
                top: w * 0.50,
                child: _Bubble(
                  icon: Icons.sports_soccer_rounded,
                  title: 'Goal Alert:',
                  subtitle: 'Team C vs Team D (1-1)',
                  scale: w / 320,
                ),
              ),
              Positioned(
                right: w * 0.08,
                top: w * 0.62,
                child: _Bubble(
                  icon: Icons.shield_rounded,
                  title: 'Match Alert',
                  subtitle: '18:30',
                  scale: w / 320,
                ),
              ),
              // The bell, glowing, anchored low-centre.
              Positioned(
                left: 0,
                right: 0,
                bottom: w * 0.10,
                child: Center(
                  child: Container(
                    width: w * 0.24,
                    height: w * 0.24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.35),
                          blurRadius: w * 0.14,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      size: w * 0.24,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.scale = 1.0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 190 * scale),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2536).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(11 * scale),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.10),
            blurRadius: 16 * scale,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22 * scale,
            height: 22 * scale,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6 * scale),
            ),
            child: Icon(icon, size: 13 * scale, color: AppColors.green),
          ),
          SizedBox(width: 8 * scale),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9 * scale,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 4 — three widget cards fanned over a pitch-marking backdrop.
class WidgetsArt extends StatelessWidget {
  const WidgetsArt({super.key});

  @override
  Widget build(BuildContext context) {
    return ArtBoard(
      badge: Icons.dashboard_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final scale = w / 320;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: w * 0.02,
                top: w * 0.30,
                child: Transform.rotate(
                  angle: -0.09,
                  child: _WidgetCard(
                    title: 'Upcoming Fixtures',
                    scale: scale,
                    rows: const [
                      ['20:45', 'LM  vs  DB'],
                      ['15:00', 'TH  vs  WV'],
                      ['14:00', 'BF  vs  NM'],
                    ],
                  ),
                ),
              ),
              Positioned(
                right: w * 0.02,
                top: w * 0.26,
                child: Transform.rotate(
                  angle: 0.09,
                  child: _WidgetCard(
                    title: 'League Table',
                    scale: scale,
                    rows: const [
                      ['1', 'LM   10   28pts'],
                      ['2', 'DB   10   25pts'],
                      ['3', 'TH   10   22pts'],
                    ],
                  ),
                ),
              ),
              // The live card sits in front, lifted and glowing.
              Align(
                alignment: const Alignment(0, -0.06),
                child: Container(
                  width: w * 0.42,
                  padding: EdgeInsets.all(11 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101A2A),
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.25),
                        blurRadius: 24 * scale,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Score',
                            style: AppText.bodyStrong.copyWith(
                              fontSize: 11 * scale,
                            ),
                          ),
                          Text(
                            "78'",
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10 * scale,
                              color: AppColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Pip(label: 'MC', scale: scale * 0.9),
                          SizedBox(width: 8 * scale),
                          Text(
                            '2 - 1',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          _Pip(label: 'AR', scale: scale * 0.9),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4 * scale),
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(5 * scale),
                        ),
                        child: Text(
                          'LEAGUE MATCH',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 7 * scale,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  const _WidgetCard({
    required this.title,
    required this.rows,
    required this.scale,
  });

  final String title;
  final List<List<String>> rows;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128 * scale,
      padding: EdgeInsets.all(9 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF16202E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(11 * scale),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppText.bodyStrong.copyWith(fontSize: 9.5 * scale),
          ),
          SizedBox(height: 7 * scale),
          for (final row in rows)
            Padding(
              padding: EdgeInsets.only(bottom: 5 * scale),
              child: Row(
                children: [
                  Text(
                    row[0],
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 7.5 * scale,
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  Expanded(
                    child: Text(
                      row[1],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 7.5 * scale,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
