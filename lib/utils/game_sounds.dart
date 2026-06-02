/// Central registry of all sound asset paths used in the game.
/// Edit paths here if you rename or move audio files.
class GameSounds {
  // Played when the question timer hits 0 and the button starts flashing
  static const String overtimeSiren = 'audio/siren_short.wav';

  // Played when a tie occurs in voting
  static const String tiePig = 'audio/pig.wav';
  static const String tieGekkon = 'audio/tie_gekkon.wav';

  // Played on every button tap across the entire app
  static const String buttonClick = 'audio/pulk.wav';

  // Played when a card is flipped
  static const String cardFlip = 'audio/whoosh.wav';

  // Played when the spy wins (hyena-sound-short.wav)
  static const String spyWin = 'audio/fahhhhhhhhhhhhhh.mp3';

  // Played when the locals win (dokumentalnyiy--realnaya-pobeda.wav)
  static const String localsWin = 'audio/pobeda_locals_win.wav';

  // Played on error/validation triggers
  static const String errorPavian = 'audio/movie_1.mp3';

  // Played when clicking Start round in preparation (sword_start.wav)
  static const String swordStart = 'audio/sword_start.wav';

  // Played when camera overlay opens (ask_photo.wav)
  static const String askPhoto = 'audio/ask_photo.wav';

  // Played when camera snap is taken (camera_flash.wav)
  static const String cameraFlash = 'audio/camera_flash.wav';

  // Played when guessing role correctly
  static const String ding = 'audio/yippeeeeeeeeeeeeee.mp3';

  // Played when guessing role wrong
  static const String bop = 'audio/fart-with-reverb.mp3';

  // Played at the end of the entire game
  static const String gameEndAirhorn = 'audio/mlg-airhorn.mp3';

  // Played when clicking ПОГНАЛИ!
  static const String pognoliVzhukh = 'audio/vzhukh.mp3';
}
