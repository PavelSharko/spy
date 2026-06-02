import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/app_settings.dart';
import '../data/locations_data.dart';

class AiGenerationService {
  // Primary: production webhook
  static const String _primaryUrl =
      'https://n8n.sharksbots.com/webhook/get-scene-picture';
  // Fallback: test webhook (only works outside browser due to CORS; used on mobile/desktop)
  static const String _fallbackUrl =
      'https://n8n.sharksbots.com/webhook-test/get-scene-picture';
  static const String _username = 'spygame';
  static const String _password = 'secretspy';

  /// Default style sent to webhook when user hasn't picked one yet.
  static const String _defaultStyle = 'как настоящее фото';

  /// Returns the style to actually send: replaces UI placeholder with real default.
  static String _effectiveStyle(String uiStyle) =>
      uiStyle == 'не выбрано' ? _defaultStyle : uiStyle;

  /// How long we wait for the server to finish generating the image.
  static const Duration _generationTimeout = Duration(seconds: 60);

  // ---------------------------------------------------------------------------
  // Shared auth
  // ---------------------------------------------------------------------------

  static String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';

  static Map<String, String> get _jsonHeaders => {
    'Authorization': _basicAuth,
    'Content-Type': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // Public API — Location card generation (gen_card_for_location)
  // ---------------------------------------------------------------------------

  /// Fetches a single location card image via JSON POST.
  /// Returns image bytes or null on failure.
  static Future<Uint8List?> fetchLocationImage(
    String locationText, {
    List<String>? roles,
  }) async {
    final settings = AppSettings.instance;
    if (!settings.uniqueCardsEnabled) {
      debugPrint(
        '[AiGenerationService] uniqueCardsEnabled is false, skipping fetch for: $locationText',
      );
      return null;
    }

    final appliedRoles = roles ?? LocationsData.roles[locationText] ?? [];

    final String body = jsonEncode({
      'location': locationText,
      'roles': appliedRoles,
      'type_query': 'gen_card_for_location',
      'generation_style': _effectiveStyle(settings.cardStyle),
      'faces_for_role': settings.playerFacesEnabled,
    });

    debugPrint('[AiGenerationService] Fetching image for: $locationText');
    return _postJsonWithFallback(body);
  }

  /// Fetches images for all locations in parallel.
  static Future<void> prefetchAllLocations({
    required List<String> locations,
    required Map<String, Uint8List> cache,
    VoidCallback? onFirstComplete,
  }) async {
    if (locations.isEmpty) return;

    if (!AppSettings.instance.uniqueCardsEnabled) {
      debugPrint(
        '[AiGenerationService] prefetchAllLocations aborted (uniqueCardsEnabled is false)',
      );
      return;
    }

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

  // ---------------------------------------------------------------------------
  // End-game card generation (gen_card_for_finish_round)
  // ---------------------------------------------------------------------------

  /// Fires two delayed background requests for finish-round cards.
  ///
  /// When [need_add_faces] is TRUE and photos exist:
  ///   → multipart/form-data: JSON payload in "data" field + photos as binary files
  ///   → n8n sees: body.data (JSON string) + binary.data0, binary.data1, ...
  ///
  /// When [need_add_faces] is FALSE or no photos:
  ///   → multipart/form-data: json payload in "body" field, NO binary files appended.
  ///
  /// Timing:
  ///   - After [delayWin]  → spy_is_win: true  → stored as "win"
  ///   - After [delayLoss] → spy_is_win: false → stored as "loss"
  static void fetchEndGameCards({
    required String location,
    required List<String> roles,
    Uint8List? spyPhoto,
    required List<Uint8List> civilianPhotos,
    required int roundNumber,
    required Map<int, Map<String, Uint8List>> targetMap,
    Duration delayWin = const Duration(seconds: 6),
    Duration delayLoss = const Duration(seconds: 12),
  }) {
    final settings = AppSettings.instance;
    if (!settings.uniqueCardsEnabled) {
      debugPrint(
        '[AiGenerationService] fetchEndGameCards skipped (uniqueCardsEnabled is false)',
      );
      return;
    }

    targetMap.putIfAbsent(roundNumber, () => {});

    // We exclusively use multipart to consistently send roles[0], roles[1] array structure,
    // regardless of whether there are actual photos.
    // Build JSON payload — identical fields to gen_card_for_location + extras
    Map<String, dynamic> buildPayload(bool spyIsWin) => {
      'location': location,
      'roles': roles,
      'type_query': 'gen_card_for_finish_round',
      'generation_style': _effectiveStyle(settings.cardStyle),
      'faces_for_role': settings.playerFacesEnabled,
      'spy_is_win': spyIsWin,
    };

    // ── Request 1: spy wins ──────────────────────────────────────────────
    Future.delayed(delayWin, () async {
      debugPrint(
        '[AiGenerationService] Sending finish-round card (spy_is_win=true) for round $roundNumber',
      );
      final payload = buildPayload(true);
      final Uint8List? result = await _postMultipartWithFallback(
        payload,
        spyPhoto,
        civilianPhotos,
      );

      if (result != null) {
        targetMap.putIfAbsent(roundNumber, () => {});
        targetMap[roundNumber]!['win'] = result;
        debugPrint(
          '[AiGenerationService] finish-round "win" card received for round $roundNumber',
        );
      }
    });

    // ── Request 2: spy loses ─────────────────────────────────────────────
    Future.delayed(delayLoss, () async {
      debugPrint(
        '[AiGenerationService] Sending finish-round card (spy_is_win=false) for round $roundNumber',
      );
      final payload = buildPayload(false);
      final Uint8List? result = await _postMultipartWithFallback(
        payload,
        spyPhoto,
        civilianPhotos,
      );

      if (result != null) {
        targetMap.putIfAbsent(roundNumber, () => {});
        targetMap[roundNumber]!['loss'] = result;
        debugPrint(
          '[AiGenerationService] finish-round "loss" card received for round $roundNumber',
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  /// Plain JSON POST with primary → fallback.
  static Future<Uint8List?> _postJsonWithFallback(String body) async {
    final headers = _jsonHeaders;

    // Primary
    try {
      final response = await http
          .post(Uri.parse(_primaryUrl), headers: headers, body: body)
          .timeout(_generationTimeout);
      debugPrint(
        '[AiGenerationService] Primary → status=${response.statusCode}',
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } on TimeoutException {
      debugPrint('[AiGenerationService] Primary timed out');
      return null;
    } catch (e) {
      debugPrint('[AiGenerationService] Primary failed ($e) — trying fallback');
    }

    // Fallback
    try {
      final response = await http
          .post(Uri.parse(_fallbackUrl), headers: headers, body: body)
          .timeout(_generationTimeout);
      debugPrint(
        '[AiGenerationService] Fallback → status=${response.statusCode}',
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } on TimeoutException {
      debugPrint('[AiGenerationService] Fallback timed out');
    } catch (e) {
      debugPrint('[AiGenerationService] Fallback failed ($e)');
    }

    return null;
  }

  /// Multipart POST with manually constructed body.
  ///
  /// Why manual? Dart's `http` package auto-adds `content-type: text/plain;
  /// charset=utf-8` + `content-transfer-encoding: binary` to any multipart
  /// field whose value contains non-ASCII characters (Russian text).  n8n sees
  /// those headers and puts the field into `binary` instead of `body`.
  ///
  /// By building the raw multipart body ourselves we control exactly what
  /// headers each part gets:
  ///   - Text fields → only `content-disposition` (no content-type) → n8n body
  ///   - Photo files → `content-disposition` with filename + `content-type:
  ///     image/jpeg` → n8n binary (data0, data1, …)
  static Future<Uint8List?> _postMultipartWithFallback(
    Map<String, dynamic> jsonPayload,
    Uint8List? spyPhoto,
    List<Uint8List> civilianPhotos,
  ) async {
    final boundary = '----SpyGame${DateTime.now().millisecondsSinceEpoch}';

    Uint8List buildBody() {
      final buf = <int>[];

      // ── Text fields (NO content-type → n8n puts them in body) ─────────
      jsonPayload.forEach((key, value) {
        if (value is List) {
          for (int j = 0; j < value.length; j++) {
            buf.addAll(utf8.encode('--$boundary\r\n'));
            buf.addAll(
              utf8.encode(
                'content-disposition: form-data; name="$key[$j]"\r\n',
              ),
            );
            buf.addAll(utf8.encode('\r\n'));
            buf.addAll(utf8.encode(value[j].toString()));
            buf.addAll(utf8.encode('\r\n'));
          }
        } else {
          buf.addAll(utf8.encode('--$boundary\r\n'));
          buf.addAll(
            utf8.encode('content-disposition: form-data; name="$key"\r\n'),
          );
          buf.addAll(utf8.encode('\r\n'));
          buf.addAll(utf8.encode(value.toString()));
          buf.addAll(utf8.encode('\r\n'));
        }
      });

      // ── Photo files (WITH content-type + filename → n8n binary) ───────
      if (spyPhoto != null) {
        buf.addAll(utf8.encode('--$boundary\r\n'));
        buf.addAll(
          utf8.encode(
            'content-disposition: form-data; name="spy_photo"; filename="spy.png"\r\n',
          ),
        );
        buf.addAll(utf8.encode('content-type: image/png\r\n'));
        buf.addAll(utf8.encode('\r\n'));
        buf.addAll(spyPhoto);
        buf.addAll(utf8.encode('\r\n'));
      }

      for (int i = 0; i < civilianPhotos.length; i++) {
        buf.addAll(utf8.encode('--$boundary\r\n'));
        buf.addAll(
          utf8.encode(
            'content-disposition: form-data; name="photo_$i"; filename="player_$i.png"\r\n',
          ),
        );
        buf.addAll(utf8.encode('content-type: image/png\r\n'));
        buf.addAll(utf8.encode('\r\n'));
        buf.addAll(civilianPhotos[i]);
        buf.addAll(utf8.encode('\r\n'));
      }

      buf.addAll(utf8.encode('--$boundary--\r\n'));
      return Uint8List.fromList(buf);
    }

    Future<Uint8List?> _send(String url) async {
      final body = buildBody();
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': _basicAuth,
              'Content-Type': 'multipart/form-data; boundary=$boundary',
            },
            body: body,
          )
          .timeout(_generationTimeout);

      debugPrint(
        '[AiGenerationService] Multipart → $url status=${response.statusCode}',
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      return null;
    }

    // Primary
    try {
      final result = await _send(_primaryUrl);
      if (result != null) return result;
    } on TimeoutException {
      debugPrint('[AiGenerationService] Multipart Primary timed out');
      return null;
    } catch (e) {
      debugPrint(
        '[AiGenerationService] Multipart Primary failed ($e) — trying fallback',
      );
    }

    // Fallback
    try {
      return await _send(_fallbackUrl);
    } on TimeoutException {
      debugPrint('[AiGenerationService] Multipart Fallback timed out');
    } catch (e) {
      debugPrint('[AiGenerationService] Multipart Fallback failed ($e)');
    }

    return null;
  }
}
