class Player {
  final String name;
  double totalScore;
  double roundScore;

  /// Role assigned at the start of each round (null for spy).
  String? role;

  Player({
    required this.name,
    this.totalScore = 0,
    this.roundScore = 0,
    this.role,
  });

  void addScore(double delta) {
    totalScore += delta;
    roundScore += delta;
  }

  void resetRoundScore() {
    roundScore = 0;
  }
}
