import 'dart:convert';
import 'package:sri_master/models/admin_models.dart';

/// Parseador para convertir JSON de usuarios a AdminUser
class UserJsonParser {
  /// Parsea un JSON string que contiene lista de usuarios
  static List<AdminUser> parseUsersJson(String jsonString) {
    try {
      final data = json.decode(jsonString);
      return parseUsersMap(data);
    } catch (e) {
      print('Error parseando JSON: $e');
      return [];
    }
  }

  /// Parsea un Map que contiene lista de usuarios
  static List<AdminUser> parseUsersMap(Map<String, dynamic> data) {
    try {
      final usersList = data['users'] as List?;
      if (usersList == null) return [];
      
      return usersList
          .map((u) => AdminUser.fromJson(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error parseando mapa de usuarios: $e');
      return [];
    }
  }

  /// Ejemplo JSON para testing
  static const String exampleJson = '''{
  "success": true,
  "total": 2,
  "users": [
    {
      "created_at": "2025-12-04T21:48:12",
      "email": "guido@example.com",
      "empresa": "",
      "id": 3,
      "is_active": 1,
      "is_admin": 0,
      "last_login": null,
      "nombre": "guido@example.com",
      "ruc": "",
      "updated_at": "2025-12-04T21:48:12",
      "username": "guido@example.com"
    },
    {
      "created_at": "2025-12-01T23:33:12",
      "email": "admin@admin.com",
      "empresa": "Sistema",
      "id": 1,
      "is_active": 1,
      "is_admin": 1,
      "last_login": "2025-12-04T21:44:23",
      "nombre": "Administrador",
      "ruc": "",
      "updated_at": "2025-12-04T21:44:23",
      "username": "admin"
    }
  ]
}''';

  /// Parsea el JSON de ejemplo para testing
  static List<AdminUser> getExampleUsers() {
    return parseUsersJson(exampleJson);
  }
}
