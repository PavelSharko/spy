/// Game rules and scoring constants.
/// Change values here to adjust game balance — RulesScreen reads these automatically.
class GameRules {
  // ── Penalty ──────────────────────────────────────────────────────────────
  /// Points deducted from a player who fails to answer in time.
  static const double penaltyOvertime = -0.1;

  /// Points deducted from a player when they view a hint.
  static const double penaltyHint = -0.1;

  // ── Spy scoring ──────────────────────────────────────────────────────────
  /// Spy guesses the location correctly during the round (mid-game secret guess).
  static const double spyWinsGuessCorrect = 4.0;

  /// Spy was NOT found by vote → spy's team wins.
  static const double spyNotFound = 2.0;

  /// Spy incorrectly guesses location early -> heavy penalty.
  static const double spyEarlyGuessIncorrectPenalty = -3.0;

  /// Spy WAS found by vote but correctly guesses the location afterwards.
  static const double spyGuessedAfterFound = 1.0;

  // ── Civilian scoring ─────────────────────────────────────────────────────
  /// Each civilian gets this many points when the spy is found by vote.
  static const double civiliansWinsVote = 1.0;

  // ── Role-guess mini-game scoring ─────────────────────────────────────────
  /// Points given to the player who guessed the correct role.
  static const double roleGuessCorrectGuesser = 1.0;

  /// Points given to the player whose role was guessed correctly.
  static const double roleGuessCorrectGuessed = 1.0;

  // ── Timer constants ───────────────────────────────────────────────────────
  /// Extra overtime seconds given before applying penalty.
  static const int overtimeSeconds = 3;

  /// Default question timer in seconds.
  static const int questionTimerSeconds = 20;

  // ── Player count limits ───────────────────────────────────────────────────
  static const int minPlayers = 3;
  static const int maxPlayers = 6;

  // ── Round limits ──────────────────────────────────────────────────────────
  static const int minRounds = 1;
  static const int maxRounds = 5;
}
