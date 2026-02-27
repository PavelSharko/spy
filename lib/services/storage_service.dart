import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service for loading and persisting game statistics (location picks, hint usage).
/// On first run it copies the bundled 'assets/data/locations_stats.json' to
/// the app's Documents directory. On subsequent runs it reads/writes from there.
///
/// On Web (kIsWeb) persistence is not available — the bundled asset is always used.
class StorageService {
  static const _statsFileName = 'locations_stats.json';

  Map<String, dynamic> _data = {};

  // ── Public API ────────────────────────────────────────────────────

  /// Call once at app start (or before using hints/selection).
  Future<void> init() async {
    _data = await _loadData();
  }

  /// Returns hint objects [{text, hint_choosed_times}, …] for [locationName].
  List<Map<String, dynamic>> getHints(String locationName) {
    final loc = _locationData(locationName);
    if (loc == null) return [];
    final raw = loc['hints_private'];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Returns all location names (flat list) sorted so less-picked come first.
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
    loc['location_chosed_times'] = ((loc['location_chosed_times'] as num?)?.toInt() ?? 0) + 1;
    await _save();
  }

  /// Increment the pick counter for a specific hint and save.
  Future<void> incrementHintPick(String locationName, String hintText) async {
    final hints = getHints(locationName);
    final idx = hints.indexWhere((h) => h['text'] == hintText);
    if (idx == -1) return;
    final loc = _locationData(locationName)!;
    (loc['hints_private'] as List)[idx]['hint_choosed_times'] =
        ((hints[idx]['hint_choosed_times'] as num?)?.toInt() ?? 0) + 1;
    await _save();
  }

  // ── Private helpers ───────────────────────────────────────────────

  Map<String, dynamic>? _locationData(String name) {
    final locs = _data['locations'] as Map<String, dynamic>?;
    final raw = locs?[name];
    if (raw == null) return null;
    return raw as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _loadData() async {
    if (kIsWeb) {
      return _loadAsset();
    }
    try {
      final file = await _localFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('StorageService: failed to read local file – $e');
    }
    final asset = await _loadAsset();
    await _writeToFile(asset);
    return asset;
  }

  Future<Map<String, dynamic>> _loadAsset() async {
    final raw = await rootBundle.loadString('assets/data/locations_stats.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _save() async {
    if (kIsWeb) return; // Can't persist on web
    await _writeToFile(_data);
  }

  Future<void> _writeToFile(Map<String, dynamic> data) async {
    try {
      final file = await _localFile();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('StorageService: failed to write file – $e');
    }
  }

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_statsFileName');
  }
}

/// Global singleton — initialise in main().
final storageService = StorageService();
