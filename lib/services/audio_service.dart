// =============================================================================
// AudioService : lit le fichier adhan.mp3 et gère le volume + stop.
//
// Encapsule un AudioPlayer du package `audioplayers`. La seule chose qu'on
// veut jouer = `assets/audio/adhan.mp3`. Si le fichier est absent (cas
// par défaut tant que tu n'as pas déposé ton propre adhan), le `try/catch`
// fait que l'app continue silencieusement — pas de crash.
//
// `isPlaying` est un ValueNotifier<bool> exposé pour que l'UI affiche un
// bouton "stop" pendant la lecture, et le masque sinon. C'est le seul état
// observable de cette classe.
// =============================================================================

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService();

  final AudioPlayer _player = AudioPlayer();

  /// True pendant la lecture de l'adhan, false sinon. Les widgets s'y
  /// abonnent via ValueListenableBuilder pour montrer/cacher le bouton stop.
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  /// Volume courant (0-1), conservé en mémoire pour le réappliquer à chaque
  /// playAdhan() — `audioplayers` réinitialise parfois le volume au play().
  double _volume = 1.0;

  /// Modifie le volume et le pousse au player. Clamp pour éviter des
  /// valeurs hors [0,1] qui sont mal gérées par certaines plateformes.
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  /// Joue l'adhan depuis le début.
  /// [assetPath] : chemin relatif dans assets/ (ex: 'audio/Adhan_al_fajr.mp3').
  /// Par défaut utilise 'audio/Adhan.mp3'.
  Future<void> playAdhan({String assetPath = 'audio/Adhan.mp3'}) async {
    try {
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.play(AssetSource(assetPath));
      isPlaying.value = true;
      _player.onPlayerComplete.first.then((_) {
        isPlaying.value = false;
      });
    } catch (_) {
      isPlaying.value = false;
    }
  }

  /// Stop manuel (bouton dans le header).
  Future<void> stop() async {
    await _player.stop();
    isPlaying.value = false;
  }

  /// Libère les ressources natives. Appelé par PrayerProvider.dispose().
  void dispose() {
    isPlaying.dispose();
    _player.dispose();
  }
}
