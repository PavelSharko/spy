import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class EndgameImageHelper {
  /// Normalizes location string to match asset file name (lowercase, underscores, no special chars)
  static String normalizeLocationName(String location) {
    String name = location.toLowerCase();
    name = name.replaceAll(' ', '_');
    // Remove all characters except a-z, а-я, 0-9, and _
    name = name.replaceAll(RegExp(r'[^a-zа-я0-9_]'), '');
    return name;
  }

  /// Returns the appropriate ImageProvider for endgame card.
  /// Priority:
  /// 1. Memory bytes (if online generation just succeeded)
  /// 2. Local File (if loaded from history on iOS/Android)
  /// 3. Asset (fallback default offline image)
  static ImageProvider getEndGameImage({
    Uint8List? memoryBytes,
    String? localPath, // Relative path from GameHistoryService
    required String location,
    required bool spyWon,
  }) {
    if (memoryBytes != null && memoryBytes.isNotEmpty) {
      return MemoryImage(memoryBytes);
    }

    if (!kIsWeb && localPath != null && localPath.isNotEmpty) {
      // NOTE: We assume the caller or this helper resolves the full path if needed, 
      // but usually GameHistoryService saves to ApplicationDocumentsDirectory/spy_game_history.
      // If we just get the relative path, we need to handle it. 
      // Actually, since this is synchronous `ImageProvider`, we can't do async `getApplicationDocumentsDirectory()` here.
      // We will assume `localPath` is the FULL absolute path if it is provided.
      final file = File(localPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    // Fallback
    final norm = normalizeLocationName(location);
    final folder = spyWon ? 'win' : 'loss';
    return AssetImage('assets/images/defaults/endgame/$folder/$norm.jpg');
  }
}
