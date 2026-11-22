import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_defs.dart';
import 'play_page.dart';
import 'widgets.dart';

/// Daily and friend-challenge games use a fixed difficulty so every player
/// faces the exact same puzzle.
void startGame(BuildContext context, GameType g,
    {int? seed, bool daily = false, bool fixed = false, bool replace = false}) {
  final page = GamePlayPage(
    game: g,
    seed: seed ?? Random().nextInt(0x7fffffff),
    daily: daily,
    fixed: fixed || daily,
  );
  final nav = Navigator.of(context);
  if (replace) {
    nav.pushReplacement(fadeRoute(page));
  } else {
    nav.push(fadeRoute(page));
  }
}
