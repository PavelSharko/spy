import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageFetchService {
  static const String _webhookUrl = 'https://n8n.sharksbots.com/webhook-test/get-scene-picture';
  static const String _username = 'spygame';
  static const String _password = 'secretspy';

  /// Fetches an image for a given location and saves it to a temporary directory.
  /// Returns the absolute path to the saved image file, or null if it failed.
  static Future<String?> fetchLocationImage(String locationText) async {
    try {
      final String basicAuth =
          'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';

      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: <String, String>{
          'authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'location': locationText,
        }),
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Find the temp directory
        final Directory tempDir = await getTemporaryDirectory();
        final String targetPath = '${tempDir.path}/spy_images';

        // Ensure the directory exists
        final Directory spyImagesDir = Directory(targetPath);
        if (!await spyImagesDir.exists()) {
          await spyImagesDir.create(recursive: true);
        }

        // Create a unique filename based on the location text
        // Encode the location text to base64 to ensure safe filename
        final String safeFilename = base64UrlEncode(utf8.encode(locationText)).replaceAll('=', '');
        final File file = File('$targetPath/$safeFilename.jpg');

        // Write the bytes to the file
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      } else {
        print('Failed to fetch image. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }
}
