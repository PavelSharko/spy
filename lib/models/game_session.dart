import 'dart:math';
import 'package:uuid/uuid.dart';
import '../data/locations_data.dart';
import 'player.dart';

class GameSession {
  final String id;
  List<Player> players;
  final int totalRounds;
  int currentRound;
  final int gameTime; // in minutes
  final String? locationGroupName;

  /// Pre-computed ordered list of secret locations — one per round.
  /// Index 0 = round 1, index 1 = round 2, etc.
  final List<String> secretLocationsQueue;

  /// Returns the secret location for the current round.
  String get currentSecretLocation => secretLocationsQueue[currentRound - 1];

  /// Allows overriding after-the-fact (kept for compatibility, not used in normal flow).
  set currentSecretLocation(String value) {
    secretLocationsQueue[currentRound - 1] = value;
  }

  int currentSpyIndex;

  GameSession({
    String? id,
    required this.players,
    required this.totalRounds,
    this.currentRound = 1,
    required this.gameTime,
    this.locationGroupName,
    required this.secretLocationsQueue,
    required this.currentSpyIndex,
  })  : assert(secretLocationsQueue.isNotEmpty),
        id = id ?? const Uuid().v4();

  Player get currentSpy => players[currentSpyIndex];

  void resetRoundScores() {
    for (var player in players) {
      player.resetRoundScore();
    }
  }

  void addScoreToSpy(double score) {
    players[currentSpyIndex].addScore(score);
  }

  void addScoreToCivilians(double score) {
    for (int i = 0; i < players.length; i++) {
      if (i != currentSpyIndex) {
        players[i].addScore(score);
      }
    }
  }

  void punishSpy(double penalty) {
    players[currentSpyIndex].addScore(penalty);
  }

  /// Assigns random roles to all non-spy players from the current location's role pool.
  /// Roles can repeat if there are more players than unique roles.
  /// Spy always gets role = null.
  void assignRoles() {
    final List<String>? pool = LocationsData.roles[currentSecretLocation];
    if (pool == null || pool.isEmpty) return;

    final shuffled = List<String>.from(pool)..shuffle(Random());

    int roleIndex = 0;
    for (int i = 0; i < players.length; i++) {
      if (i == currentSpyIndex) {
        players[i].role = null; // spy has no role
      } else {
        players[i].role = shuffled[roleIndex % shuffled.length];
        roleIndex++;
      }
    }
  }
}
