import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';
import 'game_sounds.dart';

/// Lightweight singleton for UI sound effects.
/// Call [SoundService.playClick] on any button tap.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  // Dedicated short-lived player for click sounds (low-latency)
  final AudioPlayer _clickPlayer = AudioPlayer();

  Future<void> playClick() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _clickPlayer.stop();
    await _clickPlayer.play(AssetSource(GameSounds.buttonClick));
  }

  void dispose() {
    _clickPlayer.dispose();
  }
}
