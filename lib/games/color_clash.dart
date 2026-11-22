import 'dart:math';
import 'package:flutter/material.dart';
import '../core/audio.dart';
import '../core/game_defs.dart';
import '../core/theme.dart';
import '../ui/game_scaffold.dart';
import '../l10n/l10n.dart';
import '../ui/widgets.dart';

class ColorClash extends StatefulWidget {
  final GameConfig config;
  final ValueChanged<GameResult> onDone;
  const ColorClash({super.key, required this.config, required this.onDone});
  @override
  State<ColorClash> createState() => _ColorClashState();
}

class _ColorClashState extends State<ColorClash> with TickMixin<ColorClash> {
  static const names = ['RED', 'BLUE', 'GREEN', 'YELLOW', 'PURPLE', 'ORANGE'];
  static const cols = [
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFFACC15),
    Color(0xFFA855F7),
    Color(0xFFF97316),
  ];
  late final Random rng = Random(widget.config.seed);
  late final int pool = 4 +
      (widget.config.difficulty >= 5 ? 1 : 0) +
      (widget.config.difficulty >= 8 ? 1 : 0);
  int score = 0, streak = 0, correct = 0, wrong = 0, word = 0, ink = 0;
  bool done = false;

  @override
  void initState() {
    super.initState();
    _next();
    startTimer(40, _finish);
  }

  void _next() {
    word = rng.nextInt(pool);
    ink = rng.nextDouble() < 0.25 ? word : rng.nextInt(pool);
  }

  void _answer(int i) {
    if (done) return;
    setState(() {
      if (i == ink) {
        streak++;
        correct++;
        score += 10 + min(streak, 10) * 2;
        Sfx.play('tap');
        Sfx.haptic();
      } else {
        wrong++;
        streak = 0;
        addTime(-2);
        Sfx.play('wrong');
        Sfx.haptic(heavy: true);
      }
      _next();
    });
  }

  void _finish() {
    if (done) return;
    done = true;
    stopTimer();
    final target = 26 + widget.config.difficulty * 2;
    widget.onDone(GameResult(
      game: GameType.colors,
      score: score,
      rating: ((correct - wrong * 0.5) * 100 / target).clamp(0.0, 100.0).toDouble(),
      summary: context.tr('{a} correct · {b} misses', {'a': correct, 'b': wrong}),
      seed: widget.config.seed,
      daily: widget.config.daily,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final m = GameType.colors.meta;
    return GameScaffold(
      title: context.tr(m.name),
      score: score,
      accent: m.a,
      progress: progress,
      child: Column(children: [
        SizedBox(height: 20),
        Text(streak > 1 ? context.tr('Streak x{n} 🔥', {'n': streak}) : context.tr('Tap the INK color'),
            style: TextStyle(fontSize: 15, color: C.muted, fontWeight: FontWeight.w700)),
        Spacer(),
        Text(context.tr(names[word]),
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: cols[ink])),
        Spacer(),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.3,
          physics: NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < pool; i++)
              Listener(
                onPointerDown: (_) => _answer(i),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: Text(context.tr(names[i]),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
      ]),
    );
  }
}
