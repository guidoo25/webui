import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sri_master/conts/enviroments.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static Future<bool> login({required String username, required String password}) async {
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/login');
    final body = json.encode({'username': username, 'password': password});
    try {
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final token = data['token'] ?? data['access_token'] ?? data['data']?['token'];
        if (token != null) {
          await _storage.write(key: _tokenKey, value: token.toString());
          return true;
        }
      }
    } catch (e) {}
    return false;
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<bool> register(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/register');
    try {
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: json.encode(payload)).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> saveSriCredentials(String token, Map<String, dynamic> payload) async {
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/sri-credentials');
    try {
      final res = await http.post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: json.encode(payload)).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
}
