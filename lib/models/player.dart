class Player {
  final String name;
  double totalScore;
  double roundScore;

  Player({
    required this.name,
    this.totalScore = 0,
    this.roundScore = 0,
  });

  void addScore(double delta) {
    totalScore += delta;
    roundScore += delta;
  }

  void resetRoundScore() {
    roundScore = 0;
  }
}
