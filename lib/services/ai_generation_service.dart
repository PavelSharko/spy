import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiGenerationService {
  static const String _primaryUrl =
      'https://n8n.sharksbots.com/webhook/get-scene-picture';
  static const String _fallbackUrl =
      'https://n8n.sharksbots.com/webhook-test/get-scene-picture';
  static const String _username = 'spygame';
  static const String _password = 'secretspy';

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Attempts a single POST up to [retries] times. Returns bytes on success or null.
  static Future<Uint8List?> _fetchWithRetry(
    String url,
    Map<String, String> headers,
    String body, {
    int retries = 3,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (e) {
        debugPrint('[AiGenerationService] Attempt ${i + 1} failed for $url: $e');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Fetches an AI-generated image for a given location text.
  /// Tries the primary URL (3 retries), then the fallback URL (3 retries).
  /// Returns raw image bytes as [Uint8List], or null if everything fails.
  /// Does NOT use dart:io — safe for Flutter Web.
  static Future<Uint8List?> fetchLocationImage(String locationText) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
    final Map<String, String> headers = {
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
    };
    final String body = jsonEncode({'location': locationText});

    // Attempt 1: primary URL (3 retries)
    final primary = await _fetchWithRetry(_primaryUrl, headers, body);
    if (primary != null) return primary;

    // Attempt 2: fallback URL (3 retries)
    final fallback = await _fetchWithRetry(_fallbackUrl, headers, body);
    return fallback;
  }

  /// Fetches images for all locations in parallel.
  /// Results are stored directly in [cache] as they arrive.
  /// [onFirstComplete] is called (once, on the UI-safe caller side) as soon as
  /// the very first image is successfully written to cache.
  static Future<void> prefetchAllLocations({
    required List<String> locations,
    required Map<String, Uint8List> cache,
    VoidCallback? onFirstComplete,
  }) async {
    if (locations.isEmpty) return;

    bool firstDone = false;

    // Fire all fetches in parallel; handle each result as it arrives.
    await Future.wait(
      locations.map((location) async {
        final bytes = await fetchLocationImage(location);
        if (bytes != null) {
          cache[location] = bytes;
          if (!firstDone) {
            firstDone = true;
            onFirstComplete?.call();
          }
        }
      }),
    );
  }
}
