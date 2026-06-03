import 'dart:convert';
import 'dart:typed_data';

class RoundHistory {
  final int roundNumber;
  final String? locationName;
  final String? locationImagePath;
  final String? resultImagePath;
  final Uint8List? locationImageBytes;
  final Uint8List? resultImageBytes;
  final Map<String, double> playerScores;
  final bool spyWon;
  final String? earlyEndReason;

  RoundHistory({
    required this.roundNumber,
    this.locationName,
    this.locationImagePath,
    this.resultImagePath,
    this.locationImageBytes,
    this.resultImageBytes,
    required this.playerScores,
    required this.spyWon,
    this.earlyEndReason,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'locationName': locationName,
        'locationImagePath': locationImagePath,
        'resultImagePath': resultImagePath,
        'playerScores': playerScores,
        'spyWon': spyWon,
        'earlyEndReason': earlyEndReason,
      };

  factory RoundHistory.fromJson(Map<String, dynamic> json) {
    final scores = (json['playerScores'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
    return RoundHistory(
      roundNumber: json['roundNumber'] as int,
      locationName: json['locationName'] as String?,
      locationImagePath: json['locationImagePath'] as String?,
      resultImagePath: json['resultImagePath'] as String?,
      playerScores: scores,
      spyWon: json['spyWon'] as bool? ?? false,
      earlyEndReason: json['earlyEndReason'] as String?,
    );
  }
}

class GameHistoryEntry {
  final String id;
  final DateTime date;
  final int totalRounds;
  final List<String> playerNames;
  final Map<String, double> finalScores;
  final List<RoundHistory> rounds;

  GameHistoryEntry({
    required this.id,
    required this.date,
    required this.totalRounds,
    required this.playerNames,
    required this.finalScores,
    required this.rounds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalRounds': totalRounds,
        'playerNames': playerNames,
        'finalScores': finalScores,
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    final scores = (json['finalScores'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
    return GameHistoryEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalRounds: json['totalRounds'] as int,
      playerNames: (json['playerNames'] as List<dynamic>).cast<String>(),
      finalScores: scores,
      rounds: (json['rounds'] as List<dynamic>)
          .map((r) => RoundHistory.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
