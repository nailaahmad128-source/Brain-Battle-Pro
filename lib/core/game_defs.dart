import 'package:flutter/material.dart';

enum GameType { memory, reflex, colors, logic, math }

class GameMeta {
  final String name, tagline, skill, how;
  final IconData icon;
  final Color a, b;
  const GameMeta(this.name, this.tagline, this.skill, this.how, this.icon,
      this.a, this.b);
  LinearGradient get gradient => LinearGradient(
      colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

const _metas = <GameType, GameMeta>{
  GameType.memory: GameMeta(
      'Memory Grid',
      'Watch the pattern. Repeat it.',
      'Memory',
      'Tiles light up in order. Tap them back in the same order. Three mistakes and it is over.',
      Icons.grid_view_rounded,
      Color(0xFF8B5CF6),
      Color(0xFFF472B6)),
  GameType.reflex: GameMeta(
      'Reflex Rush',
      'Tap the instant it appears.',
      'Reflex',
      '10 rounds. Wait for the glowing orb, then tap it as fast as you can. Do not tap early!',
      Icons.bolt_rounded,
      Color(0xFF22D3EE),
      Color(0xFF34D399)),
  GameType.colors: GameMeta(
      'Color Clash',
      'Trust your eyes, not the word.',
      'Focus',
      'Tap the button that matches the COLOR of the word, not what the word says. Mistakes cost time.',
      Icons.palette_rounded,
      Color(0xFFF472B6),
      Color(0xFFFBBF24)),
  GameType.logic: GameMeta(
      'Logic Chain',
      'Find the next number.',
      'Logic',
      'Spot the pattern and pick the number that comes next. Correct answers add time. Three lives.',
      Icons.psychology_rounded,
      Color(0xFF22D3EE),
      Color(0xFF8B5CF6)),
  GameType.math: GameMeta(
      'Math Blitz',
      'True or false. Fast.',
      'Math',
      'Is the equation correct? Answer as fast as you can. Wrong answers cost time.',
      Icons.calculate_rounded,
      Color(0xFFFBBF24),
      Color(0xFFF97316)),
};

extension GameTypeX on GameType {
  GameMeta get meta => _metas[this]!;
}

class GameConfig {
  final int seed, difficulty;
  final bool daily;
  const GameConfig(
      {required this.seed, required this.difficulty, this.daily = false});
}

class GameResult {
  final GameType game;
  final int score;
  final double rating; // 0..100, normalised performance
  final String summary;
  final int seed;
  final bool daily;
  const GameResult({
    required this.game,
    required this.score,
    required this.rating,
    required this.summary,
    required this.seed,
    required this.daily,
  });
  int get stars => rating >= 80 ? 3 : (rating >= 50 ? 2 : 1);
}
