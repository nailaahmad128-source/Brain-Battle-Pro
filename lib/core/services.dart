import 'leaderboard.dart';
import 'store.dart';

/// Tiny service locator (kept dependency-free on purpose).
class Svc {
  static late Store store;
  static late LeaderboardRepository board;
}
