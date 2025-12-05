import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sri_master/conts/enviroments.dart';
import 'package:sri_master/services/auth_service.dart';
import 'package:sri_master/models/admin_models.dart';

/// Servicio para operaciones de administración
class AdminService {
  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, String> _authHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== DASHBOARD ====================

  /// Obtener dashboard de admin con estadísticas
  static Future<AdminDashboard?> getAdminDashboard() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/dashboard');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return AdminDashboard.fromJson(data);
        }
      }
    } catch (e) {
      print('Error getting admin dashboard: $e');
    }
    return null;
  }

  // ==================== USUARIOS ====================

  /// Obtener todos los usuarios (admin)
  static Future<List<AdminUser>> getUsers() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final usersList = data['users'] ?? data['data'] ?? [];
          return (usersList as List).map((u) => AdminUser.fromJson(u)).toList();
        }
      }
    } catch (e) {
      print('Error getting users: $e');
    }
    return [];
  }

  /// Obtener usuario por ID con detalles completos
  static Future<AdminUser?> getUserById(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return AdminUser.fromJson(data['user'] ?? data);
        }
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  /// Crear nuevo usuario (admin)
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    String? username,
    String? nombre,
    bool isAdmin = false,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users');
      final body = json.encode({
        'email': email,
        'username': username ?? email,
        'password': password,
        'nombre': nombre ?? '',
        'is_admin': isAdmin,
      });
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {
          'success': true, 
          'user': data['user'] != null ? AdminUser.fromJson(data['user']) : null, 
          'message': data['message'] ?? 'Usuario creado exitosamente'
        };
      }
      return {'success': false, 'error': data['error'] ?? data['message'] ?? 'Error al crear usuario'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Actualizar usuario
  static Future<Map<String, dynamic>> updateUser(int userId, {
    String? nombre,
    String? email,
    String? empresa,
    bool? isAdmin,
    bool? isActive,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId');
      final body = json.encode({
        if (nombre != null) 'nombre': nombre,
        if (email != null) 'email': email,
        if (empresa != null) 'empresa': empresa,
        if (isAdmin != null) 'is_admin': isAdmin,
        if (isActive != null) 'is_active': isActive,
      });
      
      final res = await http.put(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Usuario actualizado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error actualizando usuario'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Eliminar usuario
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId');
      final res = await http.delete(uri, headers: _authHeaders(token)).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Usuario eliminado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error eliminando usuario'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Activar/Desactivar usuario (toggle)
  static Future<Map<String, dynamic>> toggleUserActive(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId/toggle-active');
      final res = await http.post(uri, headers: _authHeaders(token)).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {
          'success': true, 
          'is_active': data['is_active'],
          'message': data['message'] ?? 'Estado cambiado'
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Error cambiando estado'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== CREDENCIALES SRI ====================

  /// Obtener credenciales del usuario actual
  static Future<List<SriCredential>> getMyCredentials() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/credentials');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final credsList = data['credentials'] ?? data['data'] ?? [];
          return (credsList as List).map((c) => SriCredential.fromJson(c)).toList();
        }
      }
    } catch (e) {
      print('Error getting credentials: $e');
    }
    return [];
  }

  /// Obtener credenciales para dropdown (incluye password)
  static Future<List<CredentialOption>> getCredentialsDropdown() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/credentials/dropdown');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final optionsList = data['options'] ?? [];
          return (optionsList as List).map((o) => CredentialOption.fromJson(o)).toList();
        }
      }
    } catch (e) {
      print('Error getting credentials dropdown: $e');
    }
    return [];
  }

  /// Obtener credenciales de un usuario específico (admin)
  static Future<List<SriCredential>> getUserCredentials(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId/credentials');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final credsList = data['credentials'] ?? data['data'] ?? [];
          return (credsList as List).map((c) => SriCredential.fromJson(c)).toList();
        }
      }
    } catch (e) {
      print('Error getting user credentials: $e');
    }
    return [];
  }

  /// Agregar credencial SRI (usuario actual)
  static Future<Map<String, dynamic>> addCredential({
    required String ruc,
    required String passwordSri,
    String? ciAdicional,
    String? descripcion,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/credentials');
      final body = json.encode({
        'ruc': ruc,
        'password': passwordSri,
        'ci_adicional': ciAdicional ?? '',
        'descripcion': descripcion ?? ruc,
      });
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {
          'success': true, 
          'credential': data['credential'] != null ? SriCredential.fromJson(data['credential']) : null,
          'message': data['message'] ?? 'Credencial agregada exitosamente'
        };
      }
      return {'success': false, 'error': data['error'] ?? data['message'] ?? 'Error al agregar credencial'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Crear credencial SRI para un usuario específico (admin)
  static Future<Map<String, dynamic>> createUserCredential({
    required int userId,
    required String ruc,
    required String passwordSri,
    String? ciAdicional,
    String? descripcion,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId/credentials');
      final body = json.encode({
        'ruc': ruc,
        'password_sri': passwordSri,
        'ci_adicional': ciAdicional ?? '',
        'descripcion': descripcion ?? ruc,
      });
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {
          'success': true, 
          'credential_id': data['credential_id'],
          'message': data['message'] ?? 'Credencial creada exitosamente'
        };
      }
      return {'success': false, 'error': data['error'] ?? data['message'] ?? 'Error al crear credencial'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Actualizar credencial
  static Future<Map<String, dynamic>> updateCredential(int credentialId, {
    String? passwordSri,
    String? descripcion,
    bool? isActive,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/credentials/$credentialId');
      final body = json.encode({
        if (passwordSri != null) 'password': passwordSri,
        if (descripcion != null) 'descripcion': descripcion,
        if (isActive != null) 'is_active': isActive,
      });
      
      final res = await http.put(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Credencial actualizada'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error actualizando credencial'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Eliminar credencial (usuario actual)
  static Future<Map<String, dynamic>> deleteCredential(int credentialId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/credentials/$credentialId');
      final res = await http.delete(uri, headers: _authHeaders(token)).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Credencial eliminada'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error eliminando credencial'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Eliminar credencial de un usuario (admin)
  static Future<Map<String, dynamic>> deleteUserCredential(int userId, int credentialId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId/credentials/$credentialId');
      final res = await http.delete(uri, headers: _authHeaders(token)).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Credencial eliminada'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error eliminando credencial'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== SUSCRIPCIONES ====================

  /// Obtener todos los planes
  static Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/plans');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final plansList = data['plans'] ?? data['data'] ?? [];
          return (plansList as List).map((p) => SubscriptionPlan.fromJson(p)).toList();
        }
      }
    } catch (e) {
      print('Error getting plans: $e');
    }
    return [];
  }

  /// Obtener mi suscripción actual
  static Future<UserSubscription?> getMySubscription() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/my-subscription');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['subscription'] != null) {
          return UserSubscription.fromJson(data['subscription']);
        }
      }
    } catch (e) {
      print('Error getting subscription: $e');
    }
    return null;
  }

  /// Obtener suscripción de un usuario (admin)
  static Future<UserSubscription?> getUserSubscription(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId/subscription');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['subscription'] != null) {
          return UserSubscription.fromJson(data['subscription']);
        }
      }
    } catch (e) {
      print('Error getting user subscription: $e');
    }
    return null;
  }

  /// Cambiar plan de suscripción de un usuario (admin)
  static Future<Map<String, dynamic>> updateUserSubscription(int userId, int planId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId/subscription');
      final body = json.encode({'plan_id': planId});
      
      final res = await http.put(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Suscripción actualizada'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error actualizando suscripción'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Asignar plan a usuario (admin)
  static Future<Map<String, dynamic>> assignPlan({
    required int userId,
    required int planId,
    required String expiresAt,
    String paymentMethod = 'admin',
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscriptions/admin/assign');
      final body = json.encode({
        'user_id': userId,
        'plan_id': planId,
        'expires_at': expiresAt,
        'payment_method': paymentMethod,
      });
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Plan asignado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error asignando plan'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Crear plan (admin)
  static Future<Map<String, dynamic>> createPlan({
    required String name,
    required String code,
    required double price,
    required int maxSriCredentials,
    required int maxDownloadsMonth,
    int maxConcurrentTasks = 1,
    String? description,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/plans');
      final body = json.encode({
        'name': name,
        'code': code,
        'price': price,
        'max_sri_credentials': maxSriCredentials,
        'max_downloads_month': maxDownloadsMonth,
        'max_concurrent_tasks': maxConcurrentTasks,
        'description': description ?? '',
      });
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Plan creado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error creando plan'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Actualizar plan (admin)
  static Future<Map<String, dynamic>> updatePlan({
    required int planId,
    required String name,
    required double price,
    required int maxSriCredentials,
    required int maxDownloadsMonth,
    int maxConcurrentTasks = 1,
    String? description,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/plans/$planId');
      final body = json.encode({
        'name': name,
        'price': price,
        'max_sri_credentials': maxSriCredentials,
        'max_downloads_month': maxDownloadsMonth,
        'max_concurrent_tasks': maxConcurrentTasks,
        'description': description ?? '',
      });
      
      final res = await http.put(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Plan actualizado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error actualizando plan'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Eliminar plan (admin)
  static Future<Map<String, dynamic>> deletePlan(int planId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/plans/$planId');
      final res = await http.delete(uri, headers: _authHeaders(token)).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Plan eliminado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error eliminando plan'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== CARPETAS ====================

  /// Obtener mis carpetas de comprobantes
  static Future<List<ComprobanteFolder>> getMyFolders() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/my-comprobantes');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final foldersList = data['folders'] ?? data['data'] ?? [];
          return (foldersList as List).map((f) => ComprobanteFolder.fromJson(f)).toList();
        }
      }
    } catch (e) {
      print('Error getting folders: $e');
    }
    return [];
  }

  /// Obtener carpetas de un usuario (admin)
  static Future<List<ComprobanteFolder>> getUserFolders(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/auth/admin/users/$userId/folders');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final foldersList = data['folders'] ?? data['data'] ?? [];
          return (foldersList as List).map((f) => ComprobanteFolder.fromJson(f)).toList();
        }
      }
    } catch (e) {
      print('Error getting user folders: $e');
    }
    return [];
  }

  /// Obtener carpetas de una credencial
  static Future<List<ComprobanteFolder>> getCredentialFolders(int credentialId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/credentials/$credentialId/folders');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final foldersList = data['folders'] ?? data['data'] ?? [];
          return (foldersList as List).map((f) => ComprobanteFolder.fromJson(f)).toList();
        }
      }
    } catch (e) {
      print('Error getting credential folders: $e');
    }
    return [];
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener estadísticas del dashboard (admin)
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/admin/stats');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print('Error getting stats: $e');
    }
    return {};
  }

  /// Verificar límites de suscripción
  static Future<Map<String, dynamic>> checkLimits() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/check-limits');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print('Error checking limits: $e');
    }
    return {'can_add_credential': false, 'can_download': false};
  }

  // ==================== SUSCRIPCIÓN DE USUARIO ====================

  /// Contratar un plan de suscripción
  static Future<Map<String, dynamic>> subscribeToPlan(int planId) async {
    if (planId <= 0 || planId > 4) {
      return {
        'success': false,
        'error': 'El plan seleccionado no es válido. Debe ser 1, 2, 3 ó 4'
      };
    }
    
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/subscribe');
      final body = json.encode({'plan_id': planId});
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': data['success'] == true, 'message': data['message']};
      }
      
      return {
        'success': false,
        'error': data['message'] ?? data['error'] ?? 'Error al contratar plan'
      };
    } catch (e) {
      print('Error subscribing to plan: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Actualizar plan de suscripción
  static Future<Map<String, dynamic>> updateSubscription(int subscriptionId, int planId) async {
    if (planId <= 0 || planId > 4) {
      return {
        'success': false,
        'error': 'El plan seleccionado no es válido. Debe ser 1, 2, 3 ó 4'
      };
    }
    
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/change-plan');
      final body = json.encode({'plan_id': planId});
      
      final res = await http.put(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': data['success'] == true, 'message': data['message']};
      }
      
      return {
        'success': false,
        'error': data['message'] ?? data['error'] ?? 'Error al actualizar suscripción'
      };
    } catch (e) {
      print('Error updating subscription: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Cancelar suscripción
  static Future<Map<String, dynamic>> cancelSubscription(int subscriptionId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/$subscriptionId/cancel');
      
      final res = await http.post(uri, headers: _authHeaders(token), body: '{}').timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200) {
        return {'success': data['success'] == true, 'message': data['message']};
      }
      
      return {
        'success': false,
        'error': data['message'] ?? data['error'] ?? 'Error al cancelar suscripción'
      };
    } catch (e) {
      print('Error canceling subscription: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== GESTIÓN DE SUSCRIPCIONES (ADMIN) ====================

  /// Agregar tiempo (meses) a una suscripción (admin)
  static Future<Map<String, dynamic>> addSubscriptionTime(int userId, int months) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/user/$userId/add-time');
      final body = json.encode({'months': months});
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Tiempo agregado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error agregando tiempo'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remover tiempo (meses) de una suscripción (admin)
  static Future<Map<String, dynamic>> removeSubscriptionTime(int userId, int months) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/user/$userId/remove-time');
      final body = json.encode({'months': months});
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Tiempo removido'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error removiendo tiempo'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Cambiar plan de suscripción (admin)
  static Future<Map<String, dynamic>> adminChangePlan(int userId, int planId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/user/$userId/change-plan');
      final body = json.encode({'plan_id': planId});
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Plan cambiado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error cambiando plan'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Renovar suscripción (admin)
  static Future<Map<String, dynamic>> renewSubscription(int userId, int months) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/user/$userId/renew');
      final body = json.encode({'months': months});
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Suscripción renovada'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error renovando suscripción'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Obtener suscripción de usuario (admin)
  static Future<UserSubscription?> getAdminUserSubscription(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/user/$userId/subscription');
      
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      final data = json.decode(res.body);
      
      if (res.statusCode == 200) {
        if (data['success'] == true) {
          return UserSubscription.fromJson(data['subscription'] ?? data);
        }
      }
    } catch (e) {
      print('Error getting user subscription: $e');
    }
    return null;
  }

  /// Cancelar suscripción (admin)
  static Future<Map<String, dynamic>> adminCancelSubscription(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/user/$userId/cancel');
      
      final res = await http.post(uri, headers: _authHeaders(token), body: json.encode({})).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Suscripción cancelada'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error cancelando suscripción'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Asignar plan a usuario (admin)
  static Future<Map<String, dynamic>> assignPlanToUser(int userId, int planId, int months) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/subscription/admin/assign');
      final body = json.encode({
        'user_id': userId,
        'plan_id': planId,
        'months': months,
      });
      
      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);
      
      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Plan asignado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error asignando plan'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

/// Modelo para Dashboard de Admin
class AdminDashboard {
  final int totalUsers;
  final int activeUsers;
  final int totalCredentials;
  final Map<String, int> subscriptionsByPlan;
  final List<Map<String, dynamic>> recentUsers;

  AdminDashboard({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalCredentials,
    required this.subscriptionsByPlan,
    required this.recentUsers,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final subsByPlan = <String, int>{};
    if (json['subscriptions_by_plan'] != null) {
      for (var item in json['subscriptions_by_plan']) {
        subsByPlan[item['plan_name'] ?? 'Desconocido'] = item['count'] ?? 0;
      }
    }

    return AdminDashboard(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalCredentials: json['total_credentials'] ?? 0,
      subscriptionsByPlan: subsByPlan,
      recentUsers: (json['recent_users'] as List?)
          ?.map((u) => Map<String, dynamic>.from(u))
          .toList() ?? [],
    );
  }
}

/// Modelo para opción de dropdown de credenciales
class CredentialOption {
  final int value;
  final String label;
  final String ruc;
  final String ciAdicional;
  final String password;

  CredentialOption({
    required this.value,
    required this.label,
    required this.ruc,
    required this.ciAdicional,
    required this.password,
  });

  factory CredentialOption.fromJson(Map<String, dynamic> json) {
    return CredentialOption(
      value: json['value'] ?? json['id'] ?? 0,
      label: json['label'] ?? json['descripcion'] ?? json['ruc'] ?? '',
      ruc: json['ruc'] ?? '',
      ciAdicional: json['ci_adicional'] ?? '',
      password: json['password'] ?? json['password_sri'] ?? '',
    );
  }
}
