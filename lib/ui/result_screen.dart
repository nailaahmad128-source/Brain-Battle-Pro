import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/ads.dart';
import '../core/audio.dart';
import '../core/config.dart';
import '../core/game_defs.dart';
import '../core/services.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../l10n/l10n.dart';
import 'nav.dart';
import 'score_card.dart';
import 'widgets.dart';

class ResultScreen extends StatefulWidget {
  final GameResult result;
  final RewardSummary reward;
  const ResultScreen({super.key, required this.result, required this.reward});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _cardKey = GlobalKey();
  bool _doubled = false, _sharing = false;
  final _born = DateTime.now();

  @override
  void initState() {
    super.initState();
    AdService.instance.gameFinished();
    Sfx.play(widget.reward.leveledUp ? 'levelup' : 'win');
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final text = _shareText(context);
    final wait = 2200 - DateTime.now().difference(_born).inMilliseconds;
    if (wait > 0) await Future.delayed(Duration(milliseconds: wait));
    try {
      final b = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/brain_battle_score.png');
      await f.writeAsBytes(data!.buffer.asUint8List());
      await Share.shareXFiles([XFile(f.path)], text: text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('Could not share right now.'))));
      }
    }
    if (mounted) setState(() => _sharing = false);
  }

  String _shareText(BuildContext context) {
    final r = widget.result;
    final msg = context.tr(
        '🧠 I scored {score} in {game} on Brain Battle Pro! Beat me with challenge code {code}',
        {
          'score': r.score,
          'game': context.tr(r.game.meta.name),
          'code': encodeChallenge(r.game.index, r.seed),
        });
    return '$msg\n${AppConfig.storeUrl}';
  }

  void _doubleXp() {
    final ok = AdService.instance.showRewarded(() {
      Svc.store.addBonusXp(widget.reward.xp);
      if (mounted) setState(() => _doubled = true);
      Sfx.play('levelup');
    });
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('No ad available right now.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final rw = widget.reward;
    final big = r.stars == 3 || rw.leveledUp;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(children: [
            Column(children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    if (rw.leveledUp)
                      Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: GlassCard(
                          gradient: LinearGradient(colors: [
                            C.purple.withValues(alpha: 0.6),
                            C.cyan.withValues(alpha: 0.4),
                          ]),
                          child: Center(
                            child: Text(context.tr('⬆️ LEVEL UP!  You are now level {n}', {'n': rw.newLevel}),
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                        ),
                      ),
                    RepaintBoundary(
                      key: _cardKey,
                      child: ScoreCard(
                        result: r,
                        reward: rw,
                        level: rw.newLevel,
                        player: Svc.store.playerName,
                      ),
                    ),
                    SizedBox(height: 16),
                    GlassCard(
                      child: Row(children: [
                        Icon(Icons.bolt_rounded, color: C.gold),
                        SizedBox(width: 8),
                        Text(_doubled ? context.tr('+{n} XP (+{n} bonus)', {'n': rw.xp}) : context.tr('+{n} XP', {'n': rw.xp}),
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Spacer(),
                        if (rw.dailyBonus)
                          Text(context.tr('Daily 2× applied'),
                              style: TextStyle(color: C.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    for (final a in rw.unlocked)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: GlassCard(
                          border: C.gold.withValues(alpha: 0.5),
                          child: Row(children: [
                            Icon(a.icon, color: C.gold),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(context.tr('Achievement: {t}', {'t': context.tr(a.title)}),
                                    style: TextStyle(fontWeight: FontWeight.w800)),
                                Text(context.tr(a.desc), style: TextStyle(color: C.muted, fontSize: 12)),
                              ]),
                            ),
                            Text(context.tr('+25 XP'), style: TextStyle(color: C.gold, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                    SizedBox(height: 16),
                    GradientButton(
                      label: _sharing ? context.tr('Preparing…') : context.tr('Share score card'),
                      icon: Icons.ios_share_rounded,
                      onTap: _share,
                    ),
                    SizedBox(height: 10),
                    ValueListenableBuilder<bool>(
                      valueListenable: AdService.instance.rewardedReady,
                      builder: (_, ready, __) => (ready && !_doubled)
                          ? Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: GradientButton(
                                label: context.tr('Watch ad · +{n} bonus XP', {'n': rw.xp}),
                                icon: Icons.play_circle_rounded,
                                outlined: true,
                                onTap: _doubleXp,
                              ),
                            )
                          : SizedBox.shrink(),
                    ),
                    Row(children: [
                      Expanded(
                        child: GradientButton(
                          label: context.tr('Play again'),
                          icon: Icons.replay_rounded,
                          outlined: true,
                          onTap: () => AdService.instance.showInterstitialIfDue(() {
                            if (!mounted) return;
                            startGame(context, r.game, replace: true);
                          }),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GradientButton(
                          label: context.tr('Home'),
                          icon: Icons.home_rounded,
                          outlined: true,
                          onTap: () => AdService.instance.showInterstitialIfDue(() {
                            if (mounted) Navigator.of(context).pop();
                          }),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              BannerSlot(),
            ]),
            if (big) Positioned.fill(child: Confetti()),
          ]),
        ),
      ),
    );
  }
}
