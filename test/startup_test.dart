import 'package:brain_battle_pro/core/game_defs.dart';
import 'package:brain_battle_pro/core/leaderboard.dart';
import 'package:brain_battle_pro/core/services.dart';
import 'package:brain_battle_pro/core/store.dart';
import 'package:brain_battle_pro/games/registry.dart';
import 'package:brain_battle_pro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _initServices() async {
  SharedPreferences.setMockInitialValues({});
  Svc.store = Store(await SharedPreferences.getInstance());
  Svc.board = LocalLeaderboard(Svc.store);
}

void main() {
  testWidgets('app boots: splash -> home without exceptions', (tester) async {
    await _initServices();
    await tester.pumpWidget(const BrainBattleApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Brain Battle Pro'), findsOneWidget);
    expect(find.text('Choose your battle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every game builds and runs for a few seconds', (tester) async {
    await _initServices();
    for (final g in GameType.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildGame(g, const GameConfig(seed: 42, difficulty: 5), (_) {}),
        ),
      ));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull, reason: g.name);
      // dispose, then let any pending delayed callbacks fire (they are guarded by `mounted`)
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    }
  });
}
