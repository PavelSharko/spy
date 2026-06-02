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
  final AudioPlayer _spyWinPlayer = AudioPlayer();
  final AudioPlayer _localsWinPlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _gekkonPlayer = AudioPlayer();
  final AudioPlayer _swordPlayer = AudioPlayer();
  final AudioPlayer _askPhotoPlayer = AudioPlayer();
  final AudioPlayer _cameraFlashPlayer = AudioPlayer();
  final AudioPlayer _dingPlayer = AudioPlayer();
  final AudioPlayer _bopPlayer = AudioPlayer();
  final AudioPlayer _airhornPlayer = AudioPlayer();
  final AudioPlayer _vzhukhPlayer = AudioPlayer();

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

  Future<void> playSpyWin() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _spyWinPlayer.stop();
    await _spyWinPlayer.setVolume(0.8);
    await _spyWinPlayer.play(AssetSource(GameSounds.spyWin));
  }

  Future<void> playLocalsWin() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _localsWinPlayer.stop();
    await _localsWinPlayer.setVolume(0.8);
    await _localsWinPlayer.play(AssetSource(GameSounds.localsWin));
  }

  Future<void> playErrorPavian() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _errorPlayer.stop();
    await _errorPlayer.setVolume(0.6);
    await _errorPlayer.play(AssetSource(GameSounds.errorPavian));
  }

  Future<void> playTieGekkon() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _gekkonPlayer.stop();
    await _gekkonPlayer.setVolume(0.7);
    await _gekkonPlayer.play(AssetSource(GameSounds.tieGekkon));
  }

  Future<void> playSwordStart() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _swordPlayer.stop();
    await _swordPlayer.setVolume(0.6);
    await _swordPlayer.play(AssetSource(GameSounds.swordStart));
  }

  Future<void> playAskPhoto() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _askPhotoPlayer.stop();
    await _askPhotoPlayer.setVolume(0.7);
    await _askPhotoPlayer.play(AssetSource(GameSounds.askPhoto));
  }

  Future<void> playCameraFlash() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _cameraFlashPlayer.stop();
    await _cameraFlashPlayer.setVolume(0.7);
    await _cameraFlashPlayer.play(AssetSource(GameSounds.cameraFlash));
  }

  Future<void> playDing() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _dingPlayer.stop();
    await _dingPlayer.setVolume(0.7);
    await _dingPlayer.play(AssetSource(GameSounds.ding));
  }

  Future<void> playBop() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _bopPlayer.stop();
    await _bopPlayer.setVolume(0.7);
    await _bopPlayer.play(AssetSource(GameSounds.bop));
  }

  Future<void> playGameEndAirhorn() async {
    if (!AppSettings.instance.soundEnabled) return;
    await _airhornPlayer.stop();
    await _airhornPlayer.setVolume(0.8);
    await _airhornPlayer.play(AssetSource(GameSounds.gameEndAirhorn));
  }

  Future<void> playPognoli() async {
    if (!AppSettings.instance.soundEnabled) return;
    try {
      await _vzhukhPlayer.stop();
      await _vzhukhPlayer.setVolume(0.8);
      await _vzhukhPlayer.play(AssetSource(GameSounds.pognoliVzhukh));
    } catch (_) {
      // Web may throw on stop() before first play — safe to ignore
    }
  }

  void dispose() {
    _clickPlayer.dispose();
    _whooshPlayer.dispose();
    _sirenPlayer.dispose();
    _pigPlayer.dispose();
    _spyWinPlayer.dispose();
    _localsWinPlayer.dispose();
    _errorPlayer.dispose();
    _gekkonPlayer.dispose();
    _swordPlayer.dispose();
    _askPhotoPlayer.dispose();
    _cameraFlashPlayer.dispose();
    _dingPlayer.dispose();
    _bopPlayer.dispose();
    _airhornPlayer.dispose();
    _vzhukhPlayer.dispose();
  }
}
