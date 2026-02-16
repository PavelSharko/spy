import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/game_settings.dart';
import '../models/game_status.dart';
import '../models/location.dart';
import '../models/player.dart';

class GameProvider with ChangeNotifier {
  GameStatus _status = GameStatus.setup;
  GameSettings _settings = GameSettings();
  final List<Player> _players = [];
  
  // Getters
  GameStatus get status => _status;
  GameSettings get settings => _settings;
  List<Player> get players => _players;

  // Internal
  final _uuid = const Uuid();

  // === SETTINGS ===
  void updateSettings(GameSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  // === GAME FLOW ===

  /// Simulates starting the game (Phase 1 Corrected)
  /// Validates settings and prepares state, but then immediately finishes.
  void startGamePhase1() {
    print('Starting game Phase 1 simulation');
    print('Settings: Players=${_settings.playerCount}, RoundTime=${_settings.roundTimeSeconds}s');
    print('Rounds=${_settings.roundCount}, TurnTime=${_settings.turnTimeSeconds}s'); 
    
    _status = GameStatus.playing;
    notifyListeners();
  }

  /// Full reset to main menu
  void resetGame() {
    _status = GameStatus.setup;
    _players.clear();
    notifyListeners();
  }
}
