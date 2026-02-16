class GameSettings {
  final int playerCount;
  final int spyCount;
  final int roundTimeSeconds; // Общее время раунда
  final int roundCount; // Количество раундов
  final int turnTimeSeconds; // Время на один вопрос
  final bool isLocationRandom; // Случайные группы локаций
  final bool isNamesRandom; // Рандомные имена
  final List<String> selectedCategories; // Categories of locations to use

  GameSettings({
    this.playerCount = 3,
    this.spyCount = 1,
    this.roundTimeSeconds = 480, // 8 minutes default
    this.roundCount = 1, // Default 1 round
    this.turnTimeSeconds = 20, // Default 20 seconds per question (min 20s)
    this.isLocationRandom = true,
    this.isNamesRandom = true,
    this.selectedCategories = const [],
  });
  
  GameSettings copyWith({
    int? playerCount,
    int? spyCount,
    int? roundTimeSeconds,
    int? roundCount,
    int? turnTimeSeconds,
    bool? isLocationRandom,
    bool? isNamesRandom,
    List<String>? selectedCategories,
  }) {
    return GameSettings(
      playerCount: playerCount ?? this.playerCount,
      spyCount: spyCount ?? this.spyCount,
      roundTimeSeconds: roundTimeSeconds ?? this.roundTimeSeconds,
      roundCount: roundCount ?? this.roundCount,
      turnTimeSeconds: turnTimeSeconds ?? this.turnTimeSeconds,
      isLocationRandom: isLocationRandom ?? this.isLocationRandom,
      isNamesRandom: isNamesRandom ?? this.isNamesRandom,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }
}
