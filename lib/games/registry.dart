import 'package:flutter/material.dart';
import '../core/game_defs.dart';
import 'color_clash.dart';
import 'logic_chain.dart';
import 'math_blitz.dart';
import 'memory_grid.dart';
import 'reflex.dart';

Widget buildGame(GameType g, GameConfig c, ValueChanged<GameResult> onDone) {
  final key = ValueKey('${g.name}-${c.seed}');
  switch (g) {
    case GameType.memory:
      return MemoryGrid(key: key, config: c, onDone: onDone);
    case GameType.reflex:
      return ReflexRush(key: key, config: c, onDone: onDone);
    case GameType.colors:
      return ColorClash(key: key, config: c, onDone: onDone);
    case GameType.logic:
      return LogicChain(key: key, config: c, onDone: onDone);
    case GameType.math:
      return MathBlitz(key: key, config: c, onDone: onDone);
  }
}
