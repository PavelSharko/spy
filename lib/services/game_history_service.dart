import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';
import '../models/game_history_entry.dart';

class GameHistoryService {
  static const String _prefsKey = 'spy_game_history';

  static Future<void> saveGame(GameSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = prefs.getString(_prefsKey) ?? '[]';
      final List<dynamic> historyList = jsonDecode(historyJson);

      final List<RoundHistory> rounds = [];

      for (int r = 1; r <= session.currentRound; r++) {
        String? locName;
        String? locPath;
        String? resultPath;

        // Save location image filename
        if (r <= session.secretLocationsQueue.length) {
          locName = session.secretLocationsQueue[r - 1];
          final locBytes = session.locationImages[locName];
          if (locBytes != null && !kIsWeb) {
            final fileName = '${session.id}_round${r}_loc.png';
            try {
              final appDir = await getApplicationDocumentsDirectory();
              final historyDir = Directory('${appDir.path}/spy_game_history');
              if (!await historyDir.exists()) {
                await historyDir.create(recursive: true);
              }
              final locFile = File('${historyDir.path}/$fileName');
              await locFile.writeAsBytes(locBytes);
              locPath = fileName; // Store relative path
            } catch (fileErr) {
              debugPrint('Error writing loc file: $fileErr');
            }
          }
        }

        // Save result image (if generated)
        final spyWon = session.spyWonHistory[r] ?? false;
        final resultKey = spyWon ? 'win' : 'loss';
        final resultBytes = session.roundFinalCards[r]?[resultKey];
        if (resultBytes != null && !kIsWeb) {
          final fileName = '${session.id}_round${r}_result.png';
          try {
            final appDir = await getApplicationDocumentsDirectory();
            final historyDir = Directory('${appDir.path}/spy_game_history');
            if (!await historyDir.exists()) {
              await historyDir.create(recursive: true);
            }
            final resFile = File('${historyDir.path}/$fileName');
            await resFile.writeAsBytes(resultBytes);
            resultPath = fileName; // Store relative path
          } catch (fileErr) {
            debugPrint('Error writing result file: $fileErr');
          }
        }

        rounds.add(RoundHistory(
          roundNumber: r,
          locationName: locName,
          locationImagePath: locPath,
          resultImagePath: resultPath,
          playerScores: session.roundScoresHistory[r] ?? {},
          spyWon: spyWon,
          earlyEndReason: session.earlyEndReasons[r],
        ));
      }

      final finalScores = {for (var p in session.players) p.name: p.totalScore};
      final playerNames = session.players.map((p) => p.name).toList();

      final newEntry = GameHistoryEntry(
        id: session.id,
        date: DateTime.now(),
        totalRounds: session.currentRound, // actual played rounds
        playerNames: playerNames,
        finalScores: finalScores,
        rounds: rounds,
      );

      historyList.insert(0, newEntry.toJson());

      // Limit history to 30 games to save space
      if (historyList.length > 30) {
        // Find the oldest game and delete its files
        final oldest = GameHistoryEntry.fromJson(historyList.last as Map<String, dynamic>);
        if (!kIsWeb) {
          try {
            final appDir = await getApplicationDocumentsDirectory();
            for (var r in oldest.rounds) {
              if (r.locationImagePath != null) {
                final f = File('${appDir.path}/spy_game_history/${r.locationImagePath}');
                if (await f.exists()) await f.delete();
              }
              if (r.resultImagePath != null) {
                final f = File('${appDir.path}/spy_game_history/${r.resultImagePath}');
                if (await f.exists()) await f.delete();
              }
            }
          } catch (delErr) {
            debugPrint('Error deleting old files: $delErr');
          }
        }
        historyList.removeLast();
      }

      await prefs.setString(_prefsKey, jsonEncode(historyList));
    } catch (e) {
      debugPrint('Error saving game history: $e');
    }
  }

  static Future<List<GameHistoryEntry>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = prefs.getString(_prefsKey) ?? '[]';
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.map((e) => GameHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading game history: $e');
      return [];
    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);

      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final historyDir = Directory('${appDir.path}/spy_game_history');
        if (await historyDir.exists()) {
          await historyDir.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error clearing game history: $e');
    }
  }
}
