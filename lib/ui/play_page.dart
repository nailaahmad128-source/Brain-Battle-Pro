import 'dart:async';
import 'package:flutter/material.dart';
import '../core/audio.dart';
import '../core/game_defs.dart';
import '../core/services.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../games/registry.dart';
import '../l10n/l10n.dart';
import 'result_screen.dart';
import 'widgets.dart';

class GamePlayPage extends StatefulWidget {
  final GameType game;
  final int seed;
  final bool daily, fixed;
  const GamePlayPage({
    super.key,
    required this.game,
    required this.seed,
    required this.daily,
    required this.fixed,
  });
  @override
  State<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> {
  late final GameConfig cfg = GameConfig(
    seed: widget.seed,
    difficulty: widget.fixed ? 5 : Svc.store.mastery(widget.game),
    daily: widget.daily,
  );
  int count = 3;
  bool started = false, finished = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    Sfx.play('tick');
    _t = Timer.periodic(Duration(milliseconds: 800), (t) {
      if (!mounted) return;
      if (count > 1) {
        setState(() => count--);
        Sfx.play('tick');
      } else {
        t.cancel();
        Sfx.play('go');
        setState(() => started = true);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _onDone(GameResult r) {
    if (finished || !mounted) return;
    finished = true;
    final reward = Svc.store.record(r);
    Svc.board.submit(ScoreEntry(
      player: Svc.store.playerName,
      game: r.game.name,
      date: dayKey(),
      code: encodeChallenge(r.game.index, r.seed),
      score: r.score,
    ));
    Navigator.of(context)
        .pushReplacement(fadeRoute(ResultScreen(result: r, reward: reward)));
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('Leave this battle?')),
        content: Text(context.tr('Your progress in this round will be lost.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: Text(context.tr('Keep playing'))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.tr('Leave'), style: TextStyle(color: C.red))),
        ],
      ),
    );
    if (leave == true && mounted) {
      finished = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.game.meta;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: started
                ? buildGame(widget.game, cfg, _onDone)
                : Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(gradient: m.gradient, shape: BoxShape.circle),
                          child: Icon(m.icon, size: 44, color: Colors.white),
                        ),
                        SizedBox(height: 18),
                        Text(context.tr(m.name),
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text(
                          widget.daily
                              ? context.tr('DAILY CHALLENGE · 2× XP')
                              : (widget.fixed ? context.tr('CHALLENGE MODE') : context.tr('MASTERY LEVEL {n}', {'n': cfg.difficulty})),
                          style: TextStyle(
                              color: C.cyan, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 20),
                        Text(context.tr(m.how),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: C.muted, fontSize: 15, height: 1.4)),
                        SizedBox(height: 36),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 250),
                          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                          child: Text('$count',
                              key: ValueKey(count),
                              style: TextStyle(fontSize: 110, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
