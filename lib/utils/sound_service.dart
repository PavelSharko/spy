import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';
import 'game_sounds.dart';

/// Lightweight singleton for UI sound effects.
/// Call [SoundService.playClick] on any button tap.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  // Dedicated short-lived players for low-latency
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _whooshPlayer = AudioPlayer();
  final AudioPlayer _sirenPlayer = AudioPlayer();
  final AudioPlayer _pigPlayer = AudioPlayer();

  Future<void> playClick() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _clickPlayer.stop();
    await _clickPlayer.setVolume(0.8); // Consistent volume for clicks
    await _clickPlayer.play(AssetSource(GameSounds.buttonClick));
  }

  Future<void> playCardFlip() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _whooshPlayer.stop();
    // Lowered from 0.4 to 0.2 (the "whoosh" was too loud)
    await _whooshPlayer.setVolume(0.2); 
    await _whooshPlayer.play(AssetSource(GameSounds.cardFlip));
  }

  Future<void> playSiren() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _sirenPlayer.stop();
    await _sirenPlayer.setVolume(0.5); // Fixed volume for siren
    await _sirenPlayer.play(AssetSource(GameSounds.overtimeSiren));
  }

  Future<void> stopSiren() async {
    await _sirenPlayer.stop();
  }

  Future<void> playTiePig() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _pigPlayer.stop();
    await _pigPlayer.setVolume(0.7); // Fixed volume for pig
    await _pigPlayer.play(AssetSource(GameSounds.tiePig));
  }

  void dispose() {
    _clickPlayer.dispose();
    _whooshPlayer.dispose();
    _sirenPlayer.dispose();
    _pigPlayer.dispose();
  }
}
