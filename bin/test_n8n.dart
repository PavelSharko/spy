import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Starting standalone n8n connection test...');
  
  const primaryUrl = 'https://n8n.sharksbots.com/webhook/get-scene-picture';
  const testUrl = 'https://n8n.sharksbots.com/webhook-test/get-scene-picture';
  
  // Try to use the same credentials the app uses
  const username = 'spy_game';
  const password = 'your_real_password_here'; // Intentionally placeholder to not leak in script, but it doesn't matter for a basic connection test if we just want to see if the server responds at all (even with 401)
  
  // Actually, let's just do a basic GET request first to see if the server is even reachable
  print('\n=== Testing basic server reachability ===');
  try {
    final response = await http.get(Uri.parse('https://n8n.sharksbots.com/')).timeout(Duration(seconds: 5));
    print('Root server reached. Status: ${response.statusCode}');
  } catch (e) {
    print('Failed to reach root server: $e');
  }

  print('\n=== Testing Primary Webhook (POST without auth to see status) ===');
  try {
    final response = await http.post(
      Uri.parse(primaryUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'location': 'Test Location'}),
    ).timeout(Duration(seconds: 10));
    print('Primary Webhook Response: ${response.statusCode}');
    print('Body (first 100 chars): ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
  } catch (e) {
    print('Primary Webhook Error: $e');
  }

  print('\n=== Testing Test Webhook (POST without auth to see status) ===');
  try {
    final response = await http.post(
      Uri.parse(testUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'location': 'Test Location'}),
    ).timeout(Duration(seconds: 10));
    print('Test Webhook Response: ${response.statusCode}');
    print('Body (first 100 chars): ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
  } catch (e) {
    print('Test Webhook Error: $e');
  }
}
