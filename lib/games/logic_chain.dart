import 'dart:math';
import 'package:flutter/material.dart';
import '../core/audio.dart';
import '../core/game_defs.dart';
import '../core/theme.dart';
import '../ui/game_scaffold.dart';
import '../l10n/l10n.dart';

class LogicChain extends StatefulWidget {
  final GameConfig config;
  final ValueChanged<GameResult> onDone;
  const LogicChain({super.key, required this.config, required this.onDone});
  @override
  State<LogicChain> createState() => _LogicChainState();
}

class _LogicChainState extends State<LogicChain> with TickMixin<LogicChain> {
  late final Random rng = Random(widget.config.seed);
  List<int> shown = [];
  List<int> opts = [];
  int answer = 0, score = 0, streak = 0, correct = 0, lives = 3;
  int? picked;
  bool done = false;

  @override
  void initState() {
    super.initState();
    _gen();
    startTimer(75, _finish);
  }

  void _gen() {
    final d = widget.config.difficulty;
    final kinds = d < 3 ? 3 : (d < 6 ? 5 : 7);
    final s = List<int>.filled(6, 0);
    switch (rng.nextInt(kinds)) {
      case 0:
        final start = rng.nextInt(20) + 1, step = rng.nextInt(9) + 2;
        for (var i = 0; i < 6; i++) {
          s[i] = start + step * i;
        }
        break;
      case 1:
        final r = rng.nextInt(2) + 2;
        s[0] = rng.nextInt(3) + 1;
        for (var i = 1; i < 6; i++) {
          s[i] = s[i - 1] * r;
        }
        break;
      case 2:
        final k = rng.nextInt(3) + 1;
        s[0] = rng.nextInt(10);
        for (var i = 1; i < 6; i++) {
          s[i] = s[i - 1] + k + (i - 1);
        }
        break;
      case 3:
        final c = rng.nextInt(6), o = rng.nextInt(4) + 1;
        for (var i = 0; i < 6; i++) {
          s[i] = (i + o) * (i + o) + c;
        }
        break;
      case 4:
        s[0] = rng.nextInt(4) + 1;
        s[1] = rng.nextInt(4) + 1;
        for (var i = 2; i < 6; i++) {
          s[i] = s[i - 1] + s[i - 2];
        }
        break;
      case 5:
        final p = rng.nextInt(8) + 3, q = rng.nextInt(p - 1) + 1;
        s[0] = rng.nextInt(20) + 10;
        for (var i = 1; i < 6; i++) {
          s[i] = i.isOdd ? s[i - 1] + p : s[i - 1] - q;
        }
        break;
      default:
        s[0] = rng.nextInt(4) + 1;
        for (var i = 1; i < 6; i++) {
          s[i] = s[i - 1] * 2 + 1;
        }
    }
    shown = s.sublist(0, 5);
    answer = s[5];
    final set = <int>{answer};
    while (set.length < 4) {
      final v = answer + (rng.nextInt(9) - 4) * (1 + rng.nextInt(2));
      if (v > 0) set.add(v);
    }
    opts = set.toList()..shuffle(rng);
    picked = null;
  }

  void _pick(int i) {
    if (done || picked != null) return;
    final ok = opts[i] == answer;
    setState(() {
      picked = i;
      if (ok) {
        correct++;
        streak++;
        score += 100 + min(streak, 8) * 15;
        addTime(2);
        Sfx.play('correct');
        Sfx.haptic();
      } else {
        lives--;
        streak = 0;
        Sfx.play('wrong');
        Sfx.haptic(heavy: true);
      }
    });
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted || done) return;
      if (lives <= 0) {
        _finish();
      } else {
        setState(_gen);
      }
    });
  }

  void _finish() {
    if (done) return;
    done = true;
    stopTimer();
    widget.onDone(GameResult(
      game: GameType.logic,
      score: score,
      rating: (correct * 100 / (9 + widget.config.difficulty)).clamp(0.0, 100.0).toDouble(),
      summary: context.tr('{n} patterns solved', {'n': correct}),
      seed: widget.config.seed,
      daily: widget.config.daily,
    ));
  }

  Color _optColor(int i) {
    if (picked == null) return Colors.white.withValues(alpha: 0.07);
    if (opts[i] == answer) return C.green.withValues(alpha: 0.45);
    if (picked == i) return C.red.withValues(alpha: 0.45);
    return Colors.white.withValues(alpha: 0.04);
  }

  @override
  Widget build(BuildContext context) {
    final m = GameType.logic.meta;
    return GameScaffold(
      title: context.tr(m.name),
      score: score,
      accent: m.a,
      progress: progress,
      lives: lives,
      child: Column(children: [
        SizedBox(height: 16),
        Text(streak > 1 ? context.tr('Streak x{n} 🔥', {'n': streak}) : context.tr('What comes next?'),
            style: TextStyle(fontSize: 15, color: C.muted, fontWeight: FontWeight.w700)),
        Spacer(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in shown)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('$v',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: m.gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        Spacer(),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          physics: NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < opts.length; i++)
              Listener(
                onPointerDown: (_) => _pick(i),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: _optColor(i),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Center(
                    child: Text('${opts[i]}',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
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
