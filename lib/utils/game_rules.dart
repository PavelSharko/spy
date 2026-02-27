/// Game rules and scoring constants.
/// Change values here to adjust game balance.
class GameRules {
  // --- Penalty for slow answer (timer runs out during 3-second flash) ---
  static const double penaltyOvertime = -0.1;

  // --- Spy wins: how many points the spy gets for guessing the location correctly ---
  static const double spyWinsGuessCorrect = 4.0;

  // --- Civilians win vote: how many points each civilian gets ---
  static const double civiliansWinsVote = 1.0;

  // --- Spy not found: how many points the spy gets ---
  static const double spyNotFound = 2.0;

  // --- Additional overtime seconds shown on the button after question timer hits 0 ---
  static const int overtimeSeconds = 3;
}
