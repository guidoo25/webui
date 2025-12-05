import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sri_master/conts/enviroments.dart';
import 'package:sri_master/services/auth_service.dart';

class ApiService {
  // Login using AuthService (stores token)
  Future<bool> login(String username, String password) async {
    return await AuthService.login(username: username, password: password);
  }

  Future<List<dynamic>> getSriCredentials() async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/sri-credentials');
    final res = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['data'] ?? data['credentials'] ?? [];
    }
    return [];
  }

  Future<bool> addSriCredential({
    required String ruc,
    String? ciAdicional,
    required String passwordSri,
    String? descripcion,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/sri-credentials');
    final body = json.encode({
      'ruc': ruc,
      'ci_adicional': ciAdicional ?? '',
      'password_sri': passwordSri,
      'descripcion': descripcion ?? '',
    });
    try {
      final res = await http.post(uri, headers: _authHeaders(token)..addAll({'Content-Type':'application/json'}), body: body).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateSriCredential(int id, {String? descripcion, String? passwordSri}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/sri-credentials/$id');
    final body = json.encode({
      if (descripcion != null) 'descripcion': descripcion,
      if (passwordSri != null) 'password_sri': passwordSri,
    });
    try {
      final res = await http.put(uri, headers: _authHeaders(token)..addAll({'Content-Type':'application/json'}), body: body).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // --- Admin endpoints ---
  Future<List<dynamic>> getUsers() async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users');
    final res = await http.get(uri, headers: _authHeaders(token)).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['data'] ?? data['users'] ?? [];
    }
    return [];
  }

  Future<bool> updateUser(int id, {String? nombre, bool? isAdmin, bool? isActive}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$id');
    final body = json.encode({
      if (nombre != null) 'nombre': nombre,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (isActive != null) 'is_active': isActive,
    });
    try {
      final res = await http.put(uri, headers: _authHeaders(token)..addAll({'Content-Type':'application/json'}), body: body).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _authHeaders(String? token) {
    final headers = <String,String>{};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }
}
