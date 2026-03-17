import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiGenerationService {
  // Primary: production webhook
  static const String _primaryUrl =
      'https://n8n.sharksbots.com/webhook/get-scene-picture';
  // Fallback: test webhook (only works outside browser due to CORS; used on mobile/desktop)
  static const String _fallbackUrl =
      'https://n8n.sharksbots.com/webhook-test/get-scene-picture';
  static const String _username = 'spygame';
  static const String _password = 'secretspy';

  /// How long we wait for the server to finish generating the image.
  static const Duration _generationTimeout = Duration(seconds: 60);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Strategy:
  /// Fire both URLs in parallel. Whichever completes first with valid bytes wins.
  /// If both timeout or fail, returns null.
  /// Does NOT use dart:io — safe for Flutter Web.
  static Future<Uint8List?> fetchLocationImage(String locationText) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
    final Map<String, String> headers = {
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
    };
    final String body = jsonEncode({'location': locationText});

    debugPrint('[AiGenerationService] Fetching image for: $locationText');

    // ── Attempt 1: primary URL ────────────────────────────────────────────
    try {
      final response = await http
          .post(Uri.parse(_primaryUrl), headers: headers, body: body)
          .timeout(_generationTimeout);

      debugPrint('[AiGenerationService] Primary → status=${response.statusCode}');
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } on TimeoutException {
      debugPrint('[AiGenerationService] Primary timed out — returning null');
      return null; // Don't logic to fallback if we timed out (server is busy)
    } catch (e) {
      debugPrint('[AiGenerationService] Primary failed ($e) — trying fallback');
    }

    // ── Attempt 2: fallback URL ───────────────────────────────────────────
    try {
      final response = await http
          .post(Uri.parse(_fallbackUrl), headers: headers, body: body)
          .timeout(_generationTimeout);

      debugPrint('[AiGenerationService] Fallback → status=${response.statusCode}');
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } on TimeoutException {
      debugPrint('[AiGenerationService] Fallback timed out — returning null');
    } catch (e) {
      debugPrint('[AiGenerationService] Fallback failed ($e)');
    }

    return null;
  }

  /// Fetches images for all locations in parallel.
  /// Results are stored directly in [cache] as they arrive.
  /// [onFirstComplete] is called once when the first image is ready.
  static Future<void> prefetchAllLocations({
    required List<String> locations,
    required Map<String, Uint8List> cache,
    VoidCallback? onFirstComplete,
  }) async {
    if (locations.isEmpty) return;

    bool firstDone = false;

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
