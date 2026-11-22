import 'dart:math';
import 'package:flutter/material.dart';
import '../core/audio.dart';
import '../core/game_defs.dart';
import '../core/theme.dart';
import '../ui/game_scaffold.dart';
import '../l10n/l10n.dart';

class ReflexRush extends StatefulWidget {
  final GameConfig config;
  final ValueChanged<GameResult> onDone;
  const ReflexRush({super.key, required this.config, required this.onDone});
  @override
  State<ReflexRush> createState() => _ReflexRushState();
}

class _ReflexRushState extends State<ReflexRush> {
  static const rounds = 10;
  late final Random rng = Random(widget.config.seed);
  final times = <int>[];
  final sw = Stopwatch();
  int round = 0, score = 0, token = 0;
  bool targetOn = false, finished = false, _consumed = false, locked = false;
  int? shownMs;
  Alignment pos = Alignment.center;
  String msg = 'Get ready...';
  Color msgColor = C.muted;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    finished = true;
    super.dispose();
  }

  Future<void> _next() async {
    if (round >= rounds) {
      _finish();
      return;
    }
    round++;
    final t = ++token;
    setState(() {
      locked = false;
      shownMs = null;
      targetOn = false;
      msg = 'Wait for it...';
      msgColor = C.muted;
    });
    await Future.delayed(Duration(milliseconds: 700 + rng.nextInt(1600)));
    if (!mounted || t != token || finished) return;
    setState(() {
      pos = Alignment(rng.nextDouble() * 1.6 - 0.8, rng.nextDouble() * 1.4 - 0.7);
      targetOn = true;
      msg = '';
    });
    sw
      ..reset()
      ..start();
    Future.delayed(Duration(milliseconds: 1400), () {
      if (mounted && t == token && targetOn) _record(1400, text: 'Too slow!');
    });
  }

  void _tapTarget() {
    if (!targetOn) return;
    _consumed = true;
    sw.stop();
    _record(sw.elapsedMilliseconds);
  }

  void _early() {
    if (_consumed) {
      _consumed = false;
      return;
    }
    if (targetOn || finished || locked) return;
    _record(1000, text: 'Too early!');
  }

  Future<void> _record(int ms, {String? text}) async {
    token++;
    locked = true;
    final good = text == null;
    times.add(ms);
    score += max(0, 1000 - ms) ~/ 2;
    Sfx.play(good ? 'correct' : 'wrong');
    Sfx.haptic(heavy: !good);
    setState(() {
      targetOn = false;
      msg = text ?? '';
      shownMs = text == null ? ms : null;
      msgColor = good ? C.green : C.red;
    });
    await Future.delayed(Duration(milliseconds: 800));
    if (mounted && !finished) _next();
  }

  void _finish() {
    if (finished) return;
    finished = true;
    final avg = times.isEmpty ? 1000 : times.reduce((a, b) => a + b) ~/ times.length;
    final bestMs = times.isEmpty ? 1000 : times.reduce(min);
    widget.onDone(GameResult(
      game: GameType.reflex,
      score: score,
      rating: ((600 - avg) / 4).clamp(0.0, 100.0).toDouble(),
      summary: context.tr('Avg {a} ms · Best {b} ms', {'a': avg, 'b': bestMs}),
      seed: widget.config.seed,
      daily: widget.config.daily,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final m = GameType.reflex.meta;
    final size = max(52.0, 84.0 - widget.config.difficulty * 3);
    return GameScaffold(
      title: context.tr(m.name),
      score: score,
      accent: m.a,
      progress: round / rounds,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _early(),
        child: Stack(children: [
          Center(
            child: Text(shownMs != null ? '$shownMs ms' : context.tr(msg),
                style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: msgColor)),
          ),
          if (targetOn)
            Align(
              alignment: pos,
              child: Listener(
                onPointerDown: (_) => _tapTarget(),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Colors.white, C.cyan, C.purple]),
                    boxShadow: [
                      BoxShadow(color: C.cyan.withValues(alpha: 0.7), blurRadius: 30, spreadRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
