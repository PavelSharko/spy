class Player {
  final String name;
  int totalScore;
  int roundScore;

  Player({
    required this.name,
    this.totalScore = 0,
    this.roundScore = 0,
  });

  void addScore(int delta) {
    totalScore += delta;
    roundScore += delta;
  }

  void resetRoundScore() {
    roundScore = 0;
  }
}
