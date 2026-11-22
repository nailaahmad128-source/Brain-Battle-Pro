import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Shared in-game HUD: close button, title, score, optional timer bar and lives.
class GameScaffold extends StatelessWidget {
  final String title;
  final int score;
  final Widget child;
  final double? progress;
  final int? lives;
  final Color accent;
  const GameScaffold({
    super.key,
    required this.title,
    required this.score,
    required this.child,
    required this.accent,
    this.progress,
    this.lives,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(children: [
        Row(children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('$score',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: accent)),
          ),
        ]),
        if (p != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(p < 0.25 ? C.red : accent),
              ),
            ),
          ),
        if (lives != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: i < lives! ? C.red : Colors.white24,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: child),
      ]),
    );
  }
}

/// Countdown helper for timed games.
mixin TickMixin<T extends StatefulWidget> on State<T> {
  Timer? _timer;
  double timeLeft = 0;
  double total = 0;
  bool running = false;

  void startTimer(double seconds, VoidCallback onEnd) {
    total = seconds;
    timeLeft = seconds;
    running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !running) return;
      setState(() => timeLeft = max(0.0, timeLeft - 0.1));
      if (timeLeft <= 0) {
        running = false;
        _timer?.cancel();
        onEnd();
      }
    });
  }

  /// Call inside setState.
  void addTime(double s) => timeLeft = max(0.0, min(total, timeLeft + s));

  double get progress => total == 0 ? 0 : (timeLeft / total).clamp(0.0, 1.0).toDouble();

  void stopTimer() {
    running = false;
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
