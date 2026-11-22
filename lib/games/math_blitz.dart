import 'dart:math';
import 'package:flutter/material.dart';
import '../core/audio.dart';
import '../core/game_defs.dart';
import '../core/theme.dart';
import '../ui/game_scaffold.dart';
import '../l10n/l10n.dart';
import '../ui/widgets.dart';

class MathBlitz extends StatefulWidget {
  final GameConfig config;
  final ValueChanged<GameResult> onDone;
  const MathBlitz({super.key, required this.config, required this.onDone});
  @override
  State<MathBlitz> createState() => _MathBlitzState();
}

class _MathBlitzState extends State<MathBlitz> with TickMixin<MathBlitz> {
  late final Random rng = Random(widget.config.seed);
  String expr = '';
  int shown = 0;
  bool isTrue = true, done = false;
  int score = 0, streak = 0, correct = 0, wrong = 0;
  Color? flash;

  @override
  void initState() {
    super.initState();
    _gen();
    startTimer(45, _finish);
  }

  void _gen() {
    final d = widget.config.difficulty;
    final a = rng.nextInt(d < 3 ? 15 : (d < 6 ? 40 : 60)) + 2;
    final b = rng.nextInt(d < 3 ? 15 : 12) + 2;
    final ops = d < 3 ? ['+', '-'] : ['+', '-', '×'];
    final op = ops[rng.nextInt(ops.length)];
    var res = op == '+' ? a + b : (op == '-' ? a - b : a * b);
    var e = '$a $op $b';
    if (d >= 6) {
      final c = rng.nextInt(9) + 2;
      final op2 = rng.nextBool() ? '+' : '-';
      e += ' $op2 $c';
      res = op2 == '+' ? res + c : res - c;
    }
    isTrue = rng.nextBool();
    final off = (rng.nextInt(3) + 1) * (rng.nextBool() ? 1 : -1);
    expr = e;
    shown = isTrue ? res : res + off;
  }

  void _answer(bool says) {
    if (done) return;
    final ok = says == isTrue;
    setState(() {
      if (ok) {
        streak++;
        correct++;
        score += 10 + min(streak, 10) * 3;
        flash = C.green;
        Sfx.play('tap');
        Sfx.haptic();
      } else {
        wrong++;
        streak = 0;
        addTime(-3);
        flash = C.red;
        Sfx.play('wrong');
        Sfx.haptic(heavy: true);
      }
      _gen();
    });
    Future.delayed(Duration(milliseconds: 160), () {
      if (mounted) setState(() => flash = null);
    });
  }

  void _finish() {
    if (done) return;
    done = true;
    stopTimer();
    final target = 24 + widget.config.difficulty * 2;
    widget.onDone(GameResult(
      game: GameType.math,
      score: score,
      rating: ((correct - wrong * 0.5) * 100 / target).clamp(0.0, 100.0).toDouble(),
      summary: context.tr('{a} correct · {b} wrong', {'a': correct, 'b': wrong}),
      seed: widget.config.seed,
      daily: widget.config.daily,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final m = GameType.math.meta;
    return GameScaffold(
      title: context.tr(m.name),
      score: score,
      accent: m.a,
      progress: progress,
      child: Column(children: [
        SizedBox(height: 20),
        Text(streak > 1 ? context.tr('Streak x{n} 🔥', {'n': streak}) : context.tr('Is it correct?'),
            style: TextStyle(fontSize: 15, color: C.muted, fontWeight: FontWeight.w700)),
        Spacer(),
        AnimatedContainer(
          duration: Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: (flash ?? Colors.white).withValues(alpha: flash == null ? 0.06 : 0.25),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: FittedBox(
            child: Text('$expr = $shown',
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
          ),
        ),
        Spacer(),
        Row(children: [
          Expanded(
            child: Listener(
              onPointerDown: (_) => _answer(false),
              child: GradientButton(
                  label: context.tr('FALSE'),
                  icon: Icons.close_rounded,
                  gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)])),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Listener(
              onPointerDown: (_) => _answer(true),
              child: GradientButton(
                  label: context.tr('TRUE'),
                  icon: Icons.check_rounded,
                  gradient: LinearGradient(colors: [Color(0xFF10B981), C.cyan])),
            ),
          ),
        ]),
        SizedBox(height: 16),
      ]),
    );
  }
}
