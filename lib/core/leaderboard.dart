import 'game_defs.dart';
import 'store.dart';

/// Abstraction for leaderboards. The app only talks to this interface, so a
/// future `RemoteLeaderboard` (Firebase, Supabase, custom API) can replace
/// [LocalLeaderboard] without touching any UI or game code.
///
/// Entries carry the challenge `code` (game + seed), so an online backend can
/// rank everyone who played the exact same puzzle (daily / friend challenges).
abstract class LeaderboardRepository {
  Future<List<ScoreEntry>> top({GameType? game, int limit = 10});
  Future<void> submit(ScoreEntry entry);
}

class LocalLeaderboard implements LeaderboardRepository {
  LocalLeaderboard(this.store);
  final Store store;

  @override
  Future<List<ScoreEntry>> top({GameType? game, int limit = 10}) async {
    final all = store.scores();
    final f = game == null ? all : all.where((e) => e.game == game.name).toList();
    return f.take(limit).toList();
  }

  @override
  Future<void> submit(ScoreEntry entry) async => store.addScore(entry);
}
