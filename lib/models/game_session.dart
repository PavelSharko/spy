import 'dart:math';
import 'dart:typed_data';
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

  /// Cache of downloaded images linked to location name.
  final Map<String, Uint8List> locationImages;

  /// Cache of end-game (finish-round) card images.
  /// Key = round number, Value = {'win': imageBytes, 'loss': imageBytes}.
  final Map<int, Map<String, Uint8List>> roundFinalCards = {};

  /// Returns the secret location for the current round.
  String get currentSecretLocation => secretLocationsQueue[currentRound - 1];

  /// Allows overriding after-the-fact (kept for compatibility, not used in normal flow).
  set currentSecretLocation(String value) {
    secretLocationsQueue[currentRound - 1] = value;
  }

  int currentSpyIndex;

  /// Cache of roles selected for each location, ensuring consistency between webhook generation and assigned roles.
  final Map<String, List<String>> _selectedRoles = {};

  GameSession({
    String? id,
    required this.players,
    required this.totalRounds,
    this.currentRound = 1,
    required this.gameTime,
    this.locationGroupName,
    required this.secretLocationsQueue,
    required this.currentSpyIndex,
    Map<String, Uint8List>? locationImages,
  })  : assert(secretLocationsQueue.isNotEmpty),
        id = id ?? const Uuid().v4(),
        locationImages = locationImages ?? {} {
    // Pre-populate roles for all locations in the queue to ensure consistency
    for (final location in secretLocationsQueue) {
      _populateRolesForLocation(location);
    }
  }

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

  /// Internal helper to populate roles if not already present.
  void _populateRolesForLocation(String location) {
    if (_selectedRoles.containsKey(location)) return;

    final pool = LocationsData.roles[location];
    if (pool == null || pool.isEmpty) {
      _selectedRoles[location] = [];
      return;
    }

    final shuffled = List<String>.from(pool)..shuffle(Random());
    // Civilians count = total players - 1 spy. 
    // If players list is empty yet (initialization), we use a safe fallback or wait.
    // However, players are not yet added in PreGameFlowScreen until name selection.
    // Let's use a logic that works even with empty players list initially.
    
    // We'll leave it empty and populate on first access if needed, but with a fix.
  }

  /// Returns the pre-selected random roles for a location, ensuring consistent generation.
  List<String> getSelectedRolesForLocation(String location, {int? playerCount}) {
    if (_selectedRoles.containsKey(location) && _selectedRoles[location]!.isNotEmpty) {
      return _selectedRoles[location]!;
    }
    
    final pool = LocationsData.roles[location];
    if (pool == null || pool.isEmpty) return [];

    final shuffled = List<String>.from(pool)..shuffle(Random());
    
    // Determine how many roles we actually need.
    // If playerCount is passed, use it. Otherwise use current players list.
    int count = playerCount ?? players.length;
    int civiliansCount = count - 1;
    if (civiliansCount < 1) civiliansCount = 1;
    
    final selected = shuffled.take(civiliansCount).toList();
    _selectedRoles[location] = selected;
    return selected;
  }

  /// Assigns roles to all non-spy players from the pre-selected roles for the current location.
  /// Spy always gets role = null.
  void assignRoles() {
    final selected = getSelectedRolesForLocation(currentSecretLocation);
    if (selected.isEmpty) return;

    // Use a shuffled copy so the order of roles isn't predictable
    final randomizedAssignment = List<String>.from(selected)..shuffle(Random());

    int roleIndex = 0;
    for (int i = 0; i < players.length; i++) {
      if (i == currentSpyIndex) {
        players[i].role = null; // spy has no role
      } else {
        players[i].role = randomizedAssignment[roleIndex % randomizedAssignment.length];
        roleIndex++;
      }
    }
  }

  /// Clears all player photos and final cards to free memory.
  void clearPhotosAndFinalCards() {
    for (final player in players) {
      player.photoBytes = null;
    }
    roundFinalCards.clear();
  }
}
