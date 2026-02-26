import 'package:uuid/uuid.dart';
import 'player.dart';

class GameSession {
  final String id;
  List<Player> players;
  final int totalRounds;
  int currentRound;
  final int gameTime; // in minutes
  final String? locationGroupName;
  
  String currentSecretLocation;
  int currentSpyIndex;

  GameSession({
    String? id,
    required this.players,
    required this.totalRounds,
    this.currentRound = 1,
    required this.gameTime,
    this.locationGroupName,
    required this.currentSecretLocation,
    required this.currentSpyIndex,
  }) : id = id ?? const Uuid().v4();

  Player get currentSpy => players[currentSpyIndex];

  void resetRoundScores() {
    for (var player in players) {
      player.resetRoundScore();
    }
  }

  void addScoreToSpy(int score) {
    players[currentSpyIndex].addScore(score);
  }

  void addScoreToCivilians(int score) {
    for (int i = 0; i < players.length; i++) {
      if (i != currentSpyIndex) {
        players[i].addScore(score);
      }
    }
  }

  void punishSpy(int penalty) {
    players[currentSpyIndex].addScore(penalty);
  }
}
