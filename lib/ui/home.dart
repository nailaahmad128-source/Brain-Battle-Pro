import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/achievements.dart';
import '../core/ads.dart';
import '../core/config.dart';
import '../core/game_defs.dart';
import '../core/services.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/util.dart';
import '../l10n/l10n.dart';
import 'nav.dart';
import 'privacy_page.dart';
import 'widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _i,
              children: [PlayTab(), ProgressTab(), SettingsTab()],
            ),
          ),
        ),
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          BannerSlot(),
          NavigationBar(
            selectedIndex: _i,
            onDestinationSelected: (v) => setState(() => _i = v),
            destinations: [
              NavigationDestination(
                  icon: Icon(Icons.sports_esports_outlined),
                  selectedIcon: Icon(Icons.sports_esports_rounded),
                  label: context.tr('Play')),
              NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: context.tr('Progress')),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: context.tr('Settings')),
            ],
          ),
        ]),
      );
}

// ───────────────────────── PLAY TAB ─────────────────────────

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Svc.store,
        builder: (context, _) {
          final s = Svc.store;
          final lvl = s.level;
          final base = xpForLevel(lvl), next = xpForLevel(lvl + 1);
          final g = s.dailyGame;
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MIDO STUDIO',
                        style: TextStyle(
                            color: C.cyan, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700)),
                    ShaderMask(
                      shaderCallback: (r) => C.brand.createShader(r),
                      child: Text('Brain Battle Pro',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ]),
                ),
                GlassCard(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  radius: 16,
                  child: Row(children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: s.streak > 0 ? C.gold : C.muted, size: 22),
                    SizedBox(width: 4),
                    Text('${s.streak}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ]),
                ),
              ]),
              SizedBox(height: 18),
              GlassCard(
                child: Row(children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(gradient: C.brand, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$lvl',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(context.tr(rankTitle(lvl)),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      SizedBox(height: 8),
                      XpBar(progress: (s.xp - base) / (next - base)),
                      SizedBox(height: 4),
                      Text(context.tr('{a} / {b} XP to level {n}', {'a': s.xp - base, 'b': next - base, 'n': lvl + 1}),
                          style: TextStyle(color: C.muted, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
              SizedBox(height: 16),
              Pressable(
                onTap: () => startGame(context, g, seed: s.dailySeed, daily: true),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: g.meta.gradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                          color: g.meta.a.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: Offset(0, 10)),
                    ],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.event_available_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(context.tr('DAILY CHALLENGE'),
                              style: TextStyle(
                                  fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w800)),
                        ]),
                        SizedBox(height: 10),
                        Text(context.tr(g.meta.name),
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text(
                          s.dailyDoneToday
                              ? context.tr('Completed ✓ · new puzzle tomorrow')
                              : context.tr('Same puzzle for everyone · 2× XP'),
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ]),
                    ),
                    Icon(s.dailyDoneToday ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                        size: 58, color: Colors.white),
                  ]),
                ),
              ),
              SizedBox(height: 22),
              Text(context.tr('Choose your battle'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.98,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [for (final t in GameType.values) _GameCard(t)],
              ),
              SizedBox(height: 16),
              Pressable(
                onTap: () => _enterCode(context),
                child: GlassCard(
                  child: Row(children: [
                    Icon(Icons.group_add_rounded, color: C.cyan),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(context.tr('Challenge a friend'),
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        Text(context.tr('Got a code? Play the exact same puzzle.'),
                            style: TextStyle(color: C.muted, fontSize: 12)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.5)),
                  ]),
                ),
              ),
            ],
          );
        },
      );

  Future<void> _enterCode(BuildContext context) async {
    final ctl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('Enter challenge code')),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(hintText: 'BB-1ABC23'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(context.tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(c, ctl.text), child: Text(context.tr('Play'))),
        ],
      ),
    );
    if (code == null || !context.mounted) return;
    final d = decodeChallenge(code, GameType.values.length);
    if (d == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('That code is not valid.'))));
      return;
    }
    startGame(context, GameType.values[d.game], seed: d.seed, fixed: true);
  }
}

class _GameCard extends StatelessWidget {
  final GameType g;
  const _GameCard(this.g);
  @override
  Widget build(BuildContext context) {
    final m = g.meta;
    final s = Svc.store;
    return Pressable(
      onTap: () => startGame(context, g),
      child: GlassCard(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(gradient: m.gradient, shape: BoxShape.circle),
            child: Icon(m.icon, color: Colors.white, size: 26),
          ),
          Spacer(),
          Text(context.tr(m.name), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          SizedBox(height: 2),
          Text(context.tr(m.tagline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: C.muted, fontSize: 12)),
          SizedBox(height: 8),
          Text(context.tr('Best {a} · Lv {b}', {'a': s.best(g), 'b': s.mastery(g)}),
              style: TextStyle(color: m.a, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

// ───────────────────────── PROGRESS TAB ─────────────────────────

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Svc.store,
        builder: (context, _) {
          final s = Svc.store;
          final have = s.unlocked;
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(context.tr('Your Brain'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              SizedBox(height: 12),
              GlassCard(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ShaderMask(
                      shaderCallback: (r) => C.brand.createShader(r),
                      child: Text('${s.brainScore}',
                          style: TextStyle(
                              fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    SizedBox(width: 10),
                    Text(context.tr('Brain\nScore'),
                        style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, height: 1.2)),
                  ]),
                  RadarChart(
                    values: [for (final g in GameType.values) s.skill(g)],
                    labels: [for (final g in GameType.values) context.tr(g.meta.skill)],
                  ),
                ]),
              ),
              SizedBox(height: 14),
              Row(children: [
                _Stat('Games', '${s.totalGames}', Icons.sports_esports_rounded),
                SizedBox(width: 10),
                _Stat('Best streak', '${s.bestStreak}', Icons.local_fire_department_rounded),
                SizedBox(width: 10),
                _Stat('Total XP', '${s.xp}', Icons.bolt_rounded),
              ]),
              SizedBox(height: 22),
              Text(context.tr('Achievements {a}/{b}', {'a': have.length, 'b': kAchievements.length}),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              for (final a in kAchievements)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Opacity(
                    opacity: have.contains(a.id) ? 1 : 0.5,
                    child: GlassCard(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: have.contains(a.id) ? C.gold.withValues(alpha: 0.5) : null,
                      child: Row(children: [
                        Icon(have.contains(a.id) ? a.icon : Icons.lock_rounded,
                            color: have.contains(a.id) ? C.gold : C.muted),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(context.tr(a.title), style: TextStyle(fontWeight: FontWeight.w800)),
                            Text(context.tr(a.desc), style: TextStyle(color: C.muted, fontSize: 12)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              SizedBox(height: 14),
              Text(context.tr('Hall of Fame (this device)'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              FutureBuilder<List<ScoreEntry>>(
                future: Svc.board.top(limit: 5),
                initialData: Svc.store.scores().take(5).toList(),
                builder: (_, snap) {
                  final list = snap.data ?? const <ScoreEntry>[];
                  if (list.isEmpty) {
                    return Text(context.tr('Play a game to set your first record.'),
                        style: TextStyle(color: C.muted));
                  }
                  return Column(children: [
                    for (var i = 0; i < list.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            Text('#${i + 1}',
                                style: TextStyle(
                                    color: C.cyan, fontWeight: FontWeight.w900, fontSize: 16)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  '${context.tr(GameType.values.firstWhere((g) => g.name == list[i].game, orElse: () => GameType.memory).meta.name)} · ${list[i].date}',
                                  style: TextStyle(color: C.muted, fontSize: 13)),
                            ),
                            Text('${list[i].score}',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ]),
                        ),
                      ),
                  ]);
                },
              ),
            ],
          );
        },
      );
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Stat(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(
        child: GlassCard(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Icon(icon, color: C.cyan, size: 22),
            SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text(context.tr(label), style: TextStyle(color: C.muted, fontSize: 11)),
          ]),
        ),
      );
}

class RadarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  const RadarChart({super.key, required this.values, required this.labels});
  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.15,
        child: CustomPaint(painter: _RadarPainter(values, labels)),
      );
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  _RadarPainter(this.values, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width, size.height) / 2 - 36;
    final n = values.length;
    Offset pt(int i, double f) {
      final a = -pi / 2 + 2 * pi * i / n;
      return c + Offset(cos(a), sin(a)) * r * f;
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.12);
    for (var k = 1; k <= 4; k++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pt(i, k / 4);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, pt(i, 1), grid);
    }
    final poly = Path();
    for (var i = 0; i < n; i++) {
      final p = pt(i, max(values[i] / 100, 0.04));
      if (i == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
    }
    poly.close();
    canvas.drawPath(poly, Paint()..color = C.purple.withValues(alpha: 0.35));
    canvas.drawPath(
        poly,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = C.cyan);
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(pt(i, max(values[i] / 100, 0.04)), 4, Paint()..color = C.cyan);
      final tp = TextPainter(
        text: TextSpan(
            text: labels[i],
            style: TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      final lp = pt(i, 1.0) + (pt(i, 1.0) - c) / r * 20;
      tp.paint(canvas, lp - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}

// ───────────────────────── SETTINGS TAB ─────────────────────────

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Svc.store,
        builder: (context, _) {
          final s = Svc.store;
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(context.tr('Settings'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              SizedBox(height: 14),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  SwitchListTile(
                    title: Text(context.tr('Sound effects')),
                    value: s.sound,
                    onChanged: s.setSound,
                  ),
                  SwitchListTile(
                    title: Text(context.tr('Haptic feedback')),
                    value: s.haptics,
                    onChanged: s.setHaptics,
                  ),
                  ListTile(
                    title: Text(context.tr('Language')),
                    subtitle: Text(s.lang == null ? context.tr('System default') : langName(s.lang!)),
                    leading: Icon(Icons.language_rounded),
                    trailing: Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickLanguage(context),
                  ),
                  ListTile(
                    title: Text(context.tr('Player name')),
                    subtitle: Text(s.playerName),
                    trailing: Icon(Icons.edit_rounded, size: 20),
                    onTap: () => _editName(context),
                  ),
                  ListTile(
                    title: Text(context.tr('Privacy Policy')),
                    leading: Icon(Icons.privacy_tip_outlined),
                    trailing: Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context)
                        .push(fadeRoute(PrivacyPage())),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: AdService.instance.privacyOptionsRequired,
                    builder: (_, needed, __) => needed
                        ? ListTile(
                            title: Text(context.tr('Ad privacy choices')),
                            leading: Icon(Icons.tune_rounded),
                            trailing: Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                ConsentForm.showPrivacyOptionsForm((_) {}),
                          )
                        : SizedBox.shrink(),
                  ),
                ]),
              ),
              SizedBox(height: 14),
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(context.tr('Reset all progress'), style: TextStyle(color: C.red)),
                  leading: Icon(Icons.delete_outline_rounded, color: C.red),
                  onTap: () => _confirmReset(context),
                ),
              ),
              SizedBox(height: 28),
              Center(
                child: Text('${AppConfig.appName} v${AppConfig.version}\nby ${AppConfig.studio}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.muted, fontSize: 12, height: 1.5)),
              ),
            ],
          );
        },
      );

  Future<void> _pickLanguage(BuildContext context) async {
    final cur = Svc.store.lang;
    final picked = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(context.tr('Language')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, ''),
            child: Row(children: [
              Icon(cur == null ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: C.cyan),
              SizedBox(width: 12),
              Text(context.tr('System default')),
            ]),
          ),
          for (final l in kLanguages)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, l.$1),
              child: Row(children: [
                Icon(cur == l.$1 ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: C.cyan),
                SizedBox(width: 12),
                Text(l.$2),
              ]),
            ),
        ],
      ),
    );
    if (picked == null) return;
    Svc.store.setLang(picked.isEmpty ? null : picked);
  }

  Future<void> _editName(BuildContext context) async {
    final ctl = TextEditingController(text: Svc.store.playerName);
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('Player name')),
        content: TextField(controller: ctl, autofocus: true, maxLength: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(context.tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(c, ctl.text), child: Text(context.tr('Save'))),
        ],
      ),
    );
    if (v != null) Svc.store.setPlayerName(v);
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.tr('Reset everything?')),
        content: Text(context.tr('XP, levels, streaks, achievements and scores will be erased.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('Cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.tr('Reset'), style: TextStyle(color: C.red))),
        ],
      ),
    );
    if (ok == true) await Svc.store.reset();
  }
}
