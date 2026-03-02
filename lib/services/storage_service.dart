import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service for loading and persisting game statistics (location picks, hint usage).
///
/// Two data files are managed:
/// 1. `locations_stats.json`  — per-location stats + private hints
/// 2. `universal_hints.json`  — shared hints used across all locations
///
/// On first run each file is copied from assets to the app's Documents directory.
/// On subsequent runs the local copy is read/written (stats persist across sessions).
/// On Web persistence is not available — the bundled asset is always used.
class StorageService {
  static const _statsFileName = 'locations_stats.json';
  static const _universalFileName = 'universal_hints.json';

  Map<String, dynamic> _data = {};
  Map<String, dynamic> _universalData = {};

  // ── Public API ────────────────────────────────────────────────────

  /// Call once at app start (before using hints/selection).
  Future<void> init() async {
    _data = await _loadData(_statsFileName, 'assets/data/$_statsFileName');
    _universalData = await _loadData(_universalFileName, 'assets/data/$_universalFileName');
  }

  // ─── Location stats ──────────────────────────────────────────────

  /// Returns all location names sorted so less-picked come first.
  List<String> getAllLocationNamesSorted() {
    final locs = _data['locations'] as Map<String, dynamic>?;
    if (locs == null) return [];
    final entries = locs.entries.toList()
      ..sort((a, b) {
        final at = (a.value['location_chosed_times'] as num?)?.toInt() ?? 0;
        final bt = (b.value['location_chosed_times'] as num?)?.toInt() ?? 0;
        return at.compareTo(bt);
      });
    return entries.map((e) => e.key).toList();
  }

  /// Increment the pick counter for [locationName] and save.
  Future<void> incrementLocationPick(String locationName) async {
    final loc = _locationData(locationName);
    if (loc == null) return;
    loc['location_chosed_times'] =
        ((loc['location_chosed_times'] as num?)?.toInt() ?? 0) + 1;
    await _saveStats();
  }

  /// Smart random location picker.
  ///
  /// From [locationPool] selects [count] unique locations using the
  /// "max-gap = 2" fairness rule:
  ///   - candidates = locations where (current_count + 1) <= min_count + 2
  ///   - if fewer candidates than needed, expands to full pool
  /// Increments [location_chosed_times] for each chosen location and saves.
  /// Counters are NEVER reset — they accumulate across all play sessions.
  Future<List<String>> pickSmartLocations(
    List<String> locationPool,
    int count,
  ) async {
    if (locationPool.isEmpty || count <= 0) return [];

    // Gather current counts for pool entries
    final Map<String, int> counts = {};
    for (final name in locationPool) {
      final loc = _locationData(name);
      counts[name] = (loc?['location_chosed_times'] as num?)?.toInt() ?? 0;
    }

    final int minCount = counts.values.reduce((a, b) => a < b ? a : b);

    // Candidates: after picking, their count won't exceed min+2
    // i.e. current_count <= min + 1  (so current_count+1 <= min+2)
    List<String> candidates = locationPool
        .where((n) => (counts[n] ?? 0) <= minCount + 1)
        .toList()
      ..shuffle();

    // Safety: if not enough candidates (small pool), expand to full pool
    if (candidates.length < count) {
      candidates = List<String>.from(locationPool)..shuffle();
    }

    // Take distinct [count] entries
    final List<String> chosen = candidates.take(count).toList();

    // Increment and persist
    for (final name in chosen) {
      final loc = _locationData(name);
      if (loc != null) {
        loc['location_chosed_times'] =
            ((loc['location_chosed_times'] as num?)?.toInt() ?? 0) + 1;
      }
    }
    await _saveStats();

    return chosen;
  }

  // ─── Private hints ───────────────────────────────────────────────

  /// Returns private hint objects [{text, hint_choosed_times}, …] for [locationName].
  List<Map<String, dynamic>> getPrivateHints(String locationName) {
    final loc = _locationData(locationName);
    if (loc == null) return [];
    final raw = loc['hints_private'];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Returns the next unused private hint for [locationName] (hint_choosed_times == 0),
  /// marks it as used (sets hint_choosed_times = 1), saves, and returns its text.
  /// Returns null if all private hints have already been shown this round.
  Future<String?> pickNextPrivateHint(String locationName) async {
    final loc = _locationData(locationName);
    if (loc == null) return null;
    final raw = loc['hints_private'];
    if (raw is! List) return null;

    // Find first unused hint
    for (int i = 0; i < raw.length; i++) {
      final hint = raw[i] as Map;
      final used = (hint['hint_choosed_times'] as num?)?.toInt() ?? 0;
      if (used == 0) {
        raw[i]['hint_choosed_times'] = 1;
        await _saveStats();
        return hint['text'] as String?;
      }
    }
    return null; // All private hints exhausted for this round
  }

  /// Call at the end of a round to reset all private hint counters for [locationName].
  Future<void> resetPrivateHints(String locationName) async {
    final loc = _locationData(locationName);
    if (loc == null) return;
    final raw = loc['hints_private'];
    if (raw is! List) return;
    for (final hint in raw) {
      (hint as Map)['hint_choosed_times'] = 0;
    }
    await _saveStats();
  }

  // ─── Universal hints ─────────────────────────────────────────────

  /// Returns the next universal hint using a round-robin strategy:
  /// picks the least-used hint. If all hints have the same count (full cycle done),
  /// resets all counters to 0 first then picks again.
  /// The counter is NOT reset between rounds — it persists for the lifetime of the app.
  Future<String> pickNextUniversalHint() async {
    final hints = _universalHints();
    if (hints.isEmpty) return 'Придумайте свой вопрос!';

    // Check if all hints are at the same count → full cycle completed → reset all
    final counts = hints.map((h) => (h['hint_choosed_times'] as num?)?.toInt() ?? 0).toList();
    final minCount = counts.reduce((a, b) => a < b ? a : b);
    final maxCount = counts.reduce((a, b) => a > b ? a : b);

    if (minCount == maxCount && minCount > 0) {
      // Full cycle — reset all counters so we start fresh
      for (final hint in (_universalData['hints'] as List)) {
        (hint as Map)['hint_choosed_times'] = 0;
      }
      await _saveUniversal();
    }

    // Reload after possible reset and pick the one with lowest count
    final freshHints = _universalHints();
    freshHints.sort((a, b) =>
        ((a['hint_choosed_times'] as num?)?.toInt() ?? 0)
            .compareTo((b['hint_choosed_times'] as num?)?.toInt() ?? 0));

    final chosen = freshHints.first;
    final chosenText = chosen['text'] as String;

    // Increment in the real list by matching text
    final rawList = _universalData['hints'] as List;
    final idx = rawList.indexWhere((h) => (h as Map)['text'] == chosenText);
    if (idx != -1) {
      (rawList[idx] as Map)['hint_choosed_times'] =
          (((rawList[idx] as Map)['hint_choosed_times'] as num?)?.toInt() ?? 0) + 1;
      await _saveUniversal();
    }

    return chosenText;
  }

  // ─── Private helpers ─────────────────────────────────────────────

  List<Map<String, dynamic>> _universalHints() {
    final raw = _universalData['hints'];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, dynamic>? _locationData(String name) {
    final locs = _data['locations'] as Map<String, dynamic>?;
    final raw = locs?[name];
    if (raw == null) return null;
    return raw as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _loadData(String fileName, String assetPath) async {
    if (kIsWeb) {
      return _loadAsset(assetPath);
    }
    try {
      final file = await _localFile(fileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('StorageService: failed to read $fileName – $e');
    }
    final asset = await _loadAsset(assetPath);
    await _writeToFile(fileName, asset);
    return asset;
  }

  Future<Map<String, dynamic>> _loadAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveStats() async {
    if (kIsWeb) return;
    await _writeToFile(_statsFileName, _data);
  }

  Future<void> _saveUniversal() async {
    if (kIsWeb) return;
    await _writeToFile(_universalFileName, _universalData);
  }

  Future<void> _writeToFile(String fileName, Map<String, dynamic> data) async {
    try {
      final file = await _localFile(fileName);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('StorageService: failed to write $fileName – $e');
    }
  }

  Future<File> _localFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }
}

/// Global singleton — initialise in main().
final storageService = StorageService();
