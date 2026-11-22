import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services.dart';

class Sfx {
  static const _names = ['tap', 'correct', 'wrong', 'win', 'levelup', 'tick', 'go'];
  static final Map<String, AudioPlayer> _p = {};

  static Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
      for (final n in _names) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _p[n] = p;
      }
    } catch (e) {
      debugPrint('BBP Sfx.init failed: $e');
    }
  }

  static Future<void> play(String n) async {
    if (!Svc.store.sound) return;
    try {
      final p = _p[n];
      if (p == null) return;
      await p.stop();
      await p.play(AssetSource('sfx/$n.wav'));
    } catch (_) {}
  }

  static void haptic({bool heavy = false}) {
    if (!Svc.store.haptics) return;
    if (heavy) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }
}
