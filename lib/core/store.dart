import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievements.dart';
import 'game_defs.dart';
import 'util.dart';

class ScoreEntry {
  final String player, game, date, code;
  final int score;
  const ScoreEntry(
      {required this.player,
      required this.game,
      required this.date,
      required this.code,
      required this.score});
  Map<String, dynamic> toJson() => {
        'p': player,
        'g': game,
        'd': date,
        'c': code,
        's': score,
      };
  factory ScoreEntry.fromJson(Map<String, dynamic> j) => ScoreEntry(
        player: j['p'] as String? ?? 'Player',
        game: j['g'] as String? ?? '',
        date: j['d'] as String? ?? '',
        code: j['c'] as String? ?? '',
        score: (j['s'] as num?)?.toInt() ?? 0,
      );
}

class RewardSummary {
  final int xp, newLevel;
  final bool leveledUp, newBest, dailyBonus;
  final List<Achievement> unlocked;
  const RewardSummary({
    required this.xp,
    required this.newLevel,
    required this.leveledUp,
    required this.newBest,
    required this.dailyBonus,
    required this.unlocked,
  });
}

/// Local persistence + progression rules. Everything works offline.
class Store extends ChangeNotifier {
  Store(this._p);
  final SharedPreferences _p;

  int get xp => _p.getInt('xp') ?? 0;
  int get level => levelForXp(xp);
  int get totalGames => _p.getInt('games') ?? 0;
  int get streak => _p.getInt('streak') ?? 0;
  int get bestStreak => _p.getInt('bestStreak') ?? 0;
  int get dailyCount => _p.getInt('dailyCount') ?? 0;
  bool get sound => _p.getBool('sound') ?? true;
  bool get haptics => _p.getBool('haptics') ?? true;
  /// null = follow the device language
  String? get lang => _p.getString('lang');
  String get playerName => _p.getString('name') ?? 'Player';
  bool get dailyDoneToday => _p.getString('dailyDone') == dayKey();
  Set<String> get unlocked => (_p.getStringList('ach') ?? <String>[]).toSet();

  GameType get dailyGame =>
      GameType.values[hashString(dayKey()) % GameType.values.length];
  int get dailySeed => hashString('seed${dayKey()}');

  Map<String, dynamic> _map(String k) {
    final s = _p.getString(k);
    return s == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(s) as Map);
  }

  void _put(String k, Map<String, dynamic> m) => _p.setString(k, jsonEncode(m));

  int plays(GameType g) => (_map('plays')[g.name] as num?)?.toInt() ?? 0;
  int best(GameType g) => (_map('best')[g.name] as num?)?.toInt() ?? 0;
  double skill(GameType g) => (_map('skill')[g.name] as num?)?.toDouble() ?? 0;
  int mastery(GameType g) => (1 + plays(g) ~/ 2).clamp(1, 10).toInt();
  int get brainScore {
    final sum = GameType.values.fold<double>(0, (a, g) => a + skill(g));
    return (sum / GameType.values.length).round();
  }

  RewardSummary record(GameResult r) {
    final oldLevel = level;
    final g = r.game.name;
    final today = dayKey();

    final last = _p.getString('lastDay');
    if (last != today) {
      final y = dayKey(DateTime.now().subtract(const Duration(days: 1)));
      final s = last == y ? streak + 1 : 1;
      _p.setInt('streak', s);
      _p.setString('lastDay', today);
      if (s > bestStreak) _p.setInt('bestStreak', s);
    }

    final pl = _map('plays');
    pl[g] = ((pl[g] as num?)?.toInt() ?? 0) + 1;
    _put('plays', pl);
    _p.setInt('games', totalGames + 1);

    final bests = _map('best');
    final prev = (bests[g] as num?)?.toInt() ?? 0;
    final newBest = r.score > prev;
    if (newBest) {
      bests[g] = r.score;
      _put('best', bests);
    }

    final sk = _map('skill');
    final old = (sk[g] as num?)?.toDouble();
    sk[g] = old == null ? r.rating : old * 0.7 + r.rating * 0.3;
    _put('skill', sk);

    var gain = (12 + r.rating * 0.3 + r.score / 60).round();
    var dailyBonus = false;
    if (r.daily && !dailyDoneToday) {
      dailyBonus = true;
      gain *= 2;
      _p.setString('dailyDone', today);
      _p.setInt('dailyCount', dailyCount + 1);
    }
    _p.setInt('xp', xp + gain);

    final have = unlocked;
    final now = <Achievement>[];
    for (final a in kAchievements) {
      if (!have.contains(a.id) && a.test(this, r)) {
        now.add(a);
        have.add(a.id);
      }
    }
    if (now.isNotEmpty) {
      _p.setStringList('ach', have.toList());
      _p.setInt('xp', xp + now.length * 25);
    }
    notifyListeners();
    return RewardSummary(
      xp: gain + now.length * 25,
      newLevel: level,
      leveledUp: level > oldLevel,
      newBest: newBest,
      dailyBonus: dailyBonus,
      unlocked: now,
    );
  }

  void addBonusXp(int n) {
    _p.setInt('xp', xp + n);
    notifyListeners();
  }

  // Local leaderboard storage (see leaderboard.dart)
  List<ScoreEntry> scores() => (_p.getStringList('scores') ?? <String>[])
      .map((s) => ScoreEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .toList();

  void addScore(ScoreEntry e) {
    final all = scores()..add(e);
    all.sort((a, b) => b.score.compareTo(a.score));
    _p.setStringList(
        'scores', all.take(60).map((x) => jsonEncode(x.toJson())).toList());
    notifyListeners();
  }

  void setLang(String? code) {
    if (code == null) {
      _p.remove('lang');
    } else {
      _p.setString('lang', code);
    }
    notifyListeners();
  }

  void setSound(bool v) {
    _p.setBool('sound', v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    _p.setBool('haptics', v);
    notifyListeners();
  }

  void setPlayerName(String n) {
    final t = n.trim();
    _p.setString('name', t.isEmpty ? 'Player' : (t.length > 16 ? t.substring(0, 16) : t));
    notifyListeners();
  }

  Future<void> reset() async {
    await _p.clear();
    notifyListeners();
  }
}
