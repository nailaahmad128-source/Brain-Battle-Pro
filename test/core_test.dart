import 'package:brain_battle_pro/core/game_defs.dart';
import 'package:brain_battle_pro/core/store.dart';
import 'package:brain_battle_pro/core/util.dart';
import 'package:brain_battle_pro/l10n/l10n.dart';
import 'package:brain_battle_pro/l10n/strings.dart';
import 'package:brain_battle_pro/ui/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('level math is consistent', () {
    expect(levelForXp(0), 1);
    expect(levelForXp(100), 2);
    expect(levelForXp(300), 3);
    for (var l = 1; l < 40; l++) {
      expect(levelForXp(xpForLevel(l)), l);
    }
  });

  test('challenge codes round-trip', () {
    final code = encodeChallenge(3, 123456789);
    final d = decodeChallenge(code, 5)!;
    expect(d.game, 3);
    expect(d.seed, 123456789);
    expect(decodeChallenge('nonsense', 5), isNull);
    expect(decodeChallenge('BB-9ABC', 5), isNull);
  });

  test('recording a result grants xp and unlocks first achievement', () async {
    SharedPreferences.setMockInitialValues({});
    final s = Store(await SharedPreferences.getInstance());
    final reward = s.record(const GameResult(
      game: GameType.math,
      score: 300,
      rating: 70,
      summary: 'x',
      seed: 1,
      daily: true,
    ));
    expect(reward.xp, greaterThan(0));
    expect(reward.dailyBonus, isTrue);
    expect(s.totalGames, 1);
    expect(s.streak, 1);
    expect(s.unlocked.contains('first'), isTrue);
    expect(s.dailyDoneToday, isTrue);
  });

  testWidgets('privacy policy page renders its sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Advertising (Google AdMob)'), findsOneWidget);
  });

  test('every language has every key with matching placeholders', () {
    final ref = kStrings['ur']!;
    final ph = RegExp(r'\{[a-z]+\}');
    for (final lang in kLanguages.where((l) => l.$1 != 'en')) {
      final t = kStrings[lang.$1];
      expect(t, isNotNull, reason: lang.$1);
      expect(t!.keys.toSet(), ref.keys.toSet(), reason: lang.$1);
      t.forEach((k, v) {
        expect(v.trim(), isNotEmpty, reason: '${lang.$1}: $k');
        expect(ph.allMatches(v).map((m) => m[0]).toSet(),
            ph.allMatches(k).map((m) => m[0]).toSet(),
            reason: '${lang.$1}: $k');
      });
    }
  });

  test('trFor translates, substitutes and falls back to English', () {
    expect(trFor('ur', 'Home'), 'ہوم');
    expect(trFor('es', 'Round {n}', {'n': 3}), 'Ronda 3');
    expect(trFor('xx', 'Home'), 'Home');
    expect(trFor('ur', 'unknown key'), 'unknown key');
    expect(langName('ar'), 'العربية');
  });
}
