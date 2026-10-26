import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/prefs_provider.dart';

/// Effets sonores discrets des moments clés.
enum Sfx {
  booking,
  payment,
  notification,
  premium,
  success;

  String get asset => 'sounds/$name.wav';
}

class SoundPlayer {
  SoundPlayer(this._enabled);

  final bool Function() _enabled;
  final _players = <Sfx, AudioPlayer>{};

  /// Faux dans les tests (pas de moteur audio) : aucun son n'est joué.
  static bool get _available {
    try {
      final b = WidgetsBinding.instance;
      return !b.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!_enabled() || !_available) return;
    try {
      final p = _players.putIfAbsent(
        sfx,
        () => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
      );
      await p.stop();
      await p.play(AssetSource(sfx.asset), volume: 0.55);
    } catch (_) {
      // Son indisponible (navigateur muet, test) : jamais bloquant.
    }
  }
}

final soundProvider = Provider<SoundPlayer>(
  (ref) => SoundPlayer(() => ref.read(prefsProvider).sounds),
);
