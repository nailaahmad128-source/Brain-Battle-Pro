import 'dart:math';

int levelForXp(int xp) => ((1 + sqrt(1 + xp / 12.5)) / 2).floor();
int xpForLevel(int level) => 50 * level * (level - 1);

String dayKey([DateTime? d]) {
  final n = d ?? DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

int hashString(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

String encodeChallenge(int gameIndex, int seed) =>
    'BB-$gameIndex${seed.toRadixString(36).toUpperCase()}';

({int game, int seed})? decodeChallenge(String raw, int gameCount) {
  var c = raw.trim().toUpperCase();
  if (c.startsWith('BB-')) c = c.substring(3);
  if (c.length < 2 || c.length > 9) return null;
  final g = int.tryParse(c[0]);
  final seed = int.tryParse(c.substring(1), radix: 36);
  if (g == null || seed == null || g >= gameCount) return null;
  return (game: g, seed: seed);
}

String rankTitle(int level) {
  if (level < 3) return 'Rookie Thinker';
  if (level < 6) return 'Sharp Mind';
  if (level < 10) return 'Neuro Knight';
  if (level < 15) return 'Mind Master';
  if (level < 25) return 'Cortex Legend';
  return 'Brain Titan';
}
