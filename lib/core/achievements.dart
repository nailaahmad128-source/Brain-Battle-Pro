import 'package:flutter/material.dart';
import 'game_defs.dart';
import 'store.dart';

class Achievement {
  final String id, title, desc;
  final IconData icon;
  final bool Function(Store s, GameResult r) test;
  Achievement(this.id, this.title, this.desc, this.icon, this.test);
}

final List<Achievement> kAchievements = [
  Achievement('first', 'First Spark', 'Finish your first game',
      Icons.flare_rounded, (s, r) => true),
  Achievement('g10', 'Warmed Up', 'Play 10 games', Icons.local_fire_department_rounded,
      (s, r) => s.totalGames >= 10),
  Achievement('g50', 'Dedicated', 'Play 50 games', Icons.military_tech_rounded,
      (s, r) => s.totalGames >= 50),
  Achievement('g200', 'Brain Addict', 'Play 200 games', Icons.auto_awesome_rounded,
      (s, r) => s.totalGames >= 200),
  Achievement('l5', 'Level 5', 'Reach level 5', Icons.trending_up_rounded,
      (s, r) => s.level >= 5),
  Achievement('l10', 'Level 10', 'Reach level 10', Icons.stars_rounded,
      (s, r) => s.level >= 10),
  Achievement('l20', 'Level 20', 'Reach level 20', Icons.workspace_premium_rounded,
      (s, r) => s.level >= 20),
  Achievement('s3', 'On Fire', 'Play 3 days in a row',
      Icons.whatshot_rounded, (s, r) => s.streak >= 3),
  Achievement('s7', 'Unstoppable', 'Play 7 days in a row', Icons.bolt_rounded,
      (s, r) => s.streak >= 7),
  Achievement('s14', 'Habit Master', 'Play 14 days in a row',
      Icons.emoji_events_rounded, (s, r) => s.streak >= 14),
  Achievement('d5', 'Daily Driver', 'Finish 5 daily challenges',
      Icons.event_available_rounded, (s, r) => s.dailyCount >= 5),
  Achievement('all', 'Well Rounded', 'Play every game at least once',
      Icons.donut_large_rounded,
      (s, r) => GameType.values.every((g) => s.plays(g) > 0)),
  Achievement('mem', 'Elephant Memory', 'Memory Grid rating 80+',
      Icons.grid_view_rounded,
      (s, r) => r.game == GameType.memory && r.rating >= 80),
  Achievement('ref', 'Lightning Reflexes', 'Reflex Rush rating 90+',
      Icons.flash_on_rounded,
      (s, r) => r.game == GameType.reflex && r.rating >= 90),
  Achievement('col', 'True Colors', 'Color Clash rating 85+',
      Icons.palette_rounded,
      (s, r) => r.game == GameType.colors && r.rating >= 85),
  Achievement('log', 'Pattern Hunter', 'Logic Chain rating 85+',
      Icons.psychology_rounded,
      (s, r) => r.game == GameType.logic && r.rating >= 85),
  Achievement('mat', 'Human Calculator', 'Math Blitz rating 85+',
      Icons.calculate_rounded,
      (s, r) => r.game == GameType.math && r.rating >= 85),
  Achievement('perfect', 'Flawless', 'Get a perfect 100 rating',
      Icons.diamond_rounded, (s, r) => r.rating >= 100),
];
