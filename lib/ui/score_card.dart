import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/game_defs.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../l10n/l10n.dart';

/// The hero of the result screen AND the image that gets shared.
class ScoreCard extends StatelessWidget {
  final GameResult result;
  final RewardSummary reward;
  final int level;
  final String player;
  const ScoreCard({
    super.key,
    required this.result,
    required this.reward,
    required this.level,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final m = result.game.meta;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D1740), Color(0xFF0C1A2C)],
        ),
        border: Border.all(color: m.a.withValues(alpha: 0.65), width: 1.5),
        boxShadow: [BoxShadow(color: m.a.withValues(alpha: 0.3), blurRadius: 30)],
      ),
      child: Column(children: [
        Row(children: [
          Text('BRAIN BATTLE PRO',
              style: TextStyle(
                  fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w800, color: C.cyan)),
          Spacer(),
          if (result.daily)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: C.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(context.tr('DAILY'),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: C.gold)),
            ),
        ]),
        SizedBox(height: 18),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(gradient: m.gradient, shape: BoxShape.circle),
          child: Icon(m.icon, color: Colors.white, size: 32),
        ),
        SizedBox(height: 10),
        Text(context.tr(m.name), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: result.score),
          duration: Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ShaderMask(
            shaderCallback: (r) => C.brand.createShader(r),
            child: Text('$v',
                style: TextStyle(
                    fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05)),
          ),
        ),
        Text(context.tr('POINTS'),
            style: TextStyle(fontSize: 12, letterSpacing: 3, color: C.muted, fontWeight: FontWeight.w700)),
        SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 3; i++) _Star(index: i, filled: i < result.stars),
        ]),
        SizedBox(height: 10),
        if (reward.newBest)
          Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(context.tr('🏆 NEW PERSONAL BEST'),
                style: TextStyle(color: C.gold, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        Text(result.summary, style: TextStyle(color: C.muted, fontSize: 14)),
        SizedBox(height: 16),
        Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
        SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(player, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(context.tr('Lv {n} · {r}', {'n': level, 'r': context.tr(rankTitle(level))}),
                  style: TextStyle(color: C.muted, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(encodeChallenge(result.game.index, result.seed),
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.5, color: C.cyan, fontSize: 15)),
            Text(context.tr('Beat my score!'), style: TextStyle(color: C.muted, fontSize: 11)),
          ]),
        ]),
        SizedBox(height: 10),
        Text('${AppConfig.studio} · ${AppConfig.appName}',
            style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
      ]),
    );
  }
}

class _Star extends StatelessWidget {
  final int index;
  final bool filled;
  const _Star({required this.index, required this.filled});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + index * 250),
        curve: Curves.elasticOut,
        builder: (_, v, __) => Transform.scale(
          scale: v.clamp(0.0, 1.4).toDouble(),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 44,
            color: filled ? C.gold : Colors.white24,
          ),
        ),
      );
}
