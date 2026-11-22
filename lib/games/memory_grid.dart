import 'dart:math';
import 'package:flutter/material.dart';
import '../core/audio.dart';
import '../core/game_defs.dart';
import '../core/theme.dart';
import '../ui/game_scaffold.dart';
import '../l10n/l10n.dart';

class MemoryGrid extends StatefulWidget {
  final GameConfig config;
  final ValueChanged<GameResult> onDone;
  const MemoryGrid({super.key, required this.config, required this.onDone});
  @override
  State<MemoryGrid> createState() => _MemoryGridState();
}

class _MemoryGridState extends State<MemoryGrid> {
  late final Random rng = Random(widget.config.seed);
  late final int n = widget.config.difficulty >= 8
      ? 5
      : (widget.config.difficulty >= 4 ? 4 : 3);
  final List<int> seq = [];
  int round = 0, lives = 3, score = 0, pos = 0, bestLen = 0;
  int? lit, wrongTile;
  bool inputOn = false, over = false;
  String hint = 'Watch...';

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  @override
  void dispose() {
    over = true;
    super.dispose();
  }

  Future<void> _nextRound() async {
    round++;
    final count = round == 1 ? 3 : 1;
    for (var i = 0; i < count; i++) {
      seq.add(rng.nextInt(n * n));
    }
    await _show();
  }

  Future<void> _show() async {
    pos = 0;
    if (!mounted) return;
    setState(() {
      inputOn = false;
      hint = 'Watch...';
      wrongTile = null;
    });
    await Future.delayed(Duration(milliseconds: 650));
    final step = max(260, 480 - widget.config.difficulty * 20);
    for (final t in seq) {
      if (!mounted || over) return;
      setState(() => lit = t);
      Sfx.play('tap');
      await Future.delayed(Duration(milliseconds: step));
      if (!mounted) return;
      setState(() => lit = null);
      await Future.delayed(Duration(milliseconds: 160));
    }
    if (!mounted || over) return;
    setState(() {
      inputOn = true;
      hint = 'Your turn';
    });
  }

  Future<void> _tap(int i) async {
    if (!inputOn || over) return;
    if (seq[pos] == i) {
      Sfx.play('tap');
      Sfx.haptic();
      setState(() => lit = i);
      Future.delayed(Duration(milliseconds: 140), () {
        if (mounted) setState(() => lit = null);
      });
      pos++;
      if (pos == seq.length) {
        inputOn = false;
        bestLen = seq.length;
        score += seq.length * 20 + round * 10;
        Sfx.play('correct');
        setState(() => hint = 'Perfect!');
        await Future.delayed(Duration(milliseconds: 700));
        if (mounted && !over) _nextRound();
      }
    } else {
      Sfx.play('wrong');
      Sfx.haptic(heavy: true);
      lives--;
      inputOn = false;
      setState(() {
        wrongTile = i;
        hint = lives > 0 ? 'Oops! Watch again' : 'Game over';
      });
      await Future.delayed(Duration(milliseconds: 900));
      if (!mounted || over) return;
      if (lives <= 0) {
        _finish();
      } else {
        _show();
      }
    }
  }

  void _finish() {
    if (over) return;
    over = true;
    widget.onDone(GameResult(
      game: GameType.memory,
      score: score,
      rating: ((bestLen - 2) * 10.0).clamp(0.0, 100.0).toDouble(),
      summary: context.tr('Longest sequence: {n}', {'n': bestLen}),
      seed: widget.config.seed,
      daily: widget.config.daily,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final m = GameType.memory.meta;
    return GameScaffold(
      title: context.tr(m.name),
      score: score,
      lives: lives,
      accent: m.a,
      child: Column(children: [
        SizedBox(height: 18),
        Text(context.tr('Round {n}', {'n': round}),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        SizedBox(height: 4),
        Text(context.tr(hint), style: TextStyle(fontSize: 15, color: C.muted)),
        Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.count(
              crossAxisCount: n,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < n * n; i++)
                  Listener(
                    onPointerDown: (_) => _tap(i),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        gradient: lit == i ? m.gradient : null,
                        color: wrongTile == i
                            ? C.red.withValues(alpha: 0.8)
                            : (lit == i ? null : Colors.white.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: lit == i
                            ? [BoxShadow(color: m.a.withValues(alpha: 0.6), blurRadius: 20)]
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Spacer(flex: 2),
      ]),
    );
  }
}
