import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playAdhan() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/adhan.mp3'));
    } catch (_) {
      // Silently fail if audio file is missing or playback errors.
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
