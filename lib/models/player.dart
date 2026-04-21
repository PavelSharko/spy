import 'dart:typed_data';

class Player {
  final String name;
  double totalScore;
  double roundScore;

  /// Role assigned at the start of each round (null for spy).
  String? role;

  /// Photo bytes captured via camera (used for unique card generation).
  Uint8List? photoBytes;

  Player({
    required this.name,
    this.totalScore = 0,
    this.roundScore = 0,
    this.role,
    this.photoBytes,
  });

  void addScore(double delta) {
    totalScore += delta;
    roundScore += delta;
  }

  void resetRoundScore() {
    roundScore = 0;
  }
}
