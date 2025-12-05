import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sri_master/conts/enviroments.dart';
import 'package:sri_master/services/auth_service.dart';
import 'package:sri_master/models/payment_models.dart';

/// Servicio para operaciones de pagos
class PaymentService {
  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, String> _authHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== PÚBLICO ====================

  /// Obtener métodos de pago disponibles
  static Future<PaymentMethodsResponse?> getPaymentMethods() async {
    try {
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/methods');
      final res = await http.get(uri).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return PaymentMethodsResponse.fromJson(data);
      }
    } catch (e) {
      print('Error getting payment methods: $e');
    }
    return null;
  }

  /// Obtener métodos de pago de un usuario específico (admin)
  static Future<List<PaymentMethod>> getUserPaymentMethods(int userId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/users/$userId/methods');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true || data is List) {
          final methodsList = data['methods'] ?? data['data'] ?? data ?? [];
          return (methodsList as List)
              .map((m) => PaymentMethod.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('Error getting user payment methods: $e');
    }
    return [];
  }

  /// Obtener detalle de un método de pago
  static Future<PaymentMethod?> getPaymentMethodById(int methodId) async {
    try {
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/methods/$methodId');
      final res = await http.get(uri).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return PaymentMethod.fromJson(data['method'] ?? data);
        }
      }
    } catch (e) {
      print('Error getting payment method: $e');
    }
    return null;
  }

  // ==================== USUARIO ====================

  /// Subir comprobante de pago (soporta Web y Nativo)
  static Future<Map<String, dynamic>> uploadPaymentProof({
    required String filePath,
    required int paymentMethodId,
    required double amount,
    int? subscriptionId,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/proofs');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['payment_method_id'] = paymentMethodId.toString();
      request.fields['amount'] = amount.toString();
      if (subscriptionId != null) {
        request.fields['subscription_id'] = subscriptionId.toString();
      }
      
      if (kIsWeb) {
        // Para WEB: Usar bytes directamente de XFile
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
        
        if (pickedFile == null) {
          return {'success': false, 'error': 'No se seleccionó archivo'};
        }
        
        final bytes = await pickedFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'proof',
          bytes,
          filename: pickedFile.name,
        ));
      } else {
        // Para Nativo (Android, iOS, Windows, macOS, Linux): Usar ruta directa
        try {
          request.files.add(await http.MultipartFile.fromPath('proof', filePath));
        } catch (e) {
          // Fallback: leer como bytes si falla
          final file = io.File(filePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'proof',
              bytes,
              filename: file.path.split('/').last,
            ));
          } else {
            return {'success': false, 'error': 'El archivo no existe'};
          }
        }
      }

      final res = await request.send().timeout(_timeout);
      final responseBody = await res.stream.bytesToString();
      final data = json.decode(responseBody);

      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Comprobante enviado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error al subir comprobante'};
    } catch (e) {
      print('Error uploading proof: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Obtener mis comprobantes
  static Future<List<PaymentProof>> getMyProofs() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/proofs');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final proofsList = data['proofs'] ?? data['data'] ?? [];
          return (proofsList as List)
              .map((p) => PaymentProof.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('Error getting proofs: $e');
    }
    return [];
  }

  /// Obtener detalle de un comprobante
  static Future<PaymentProof?> getProofById(int proofId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/proofs/$proofId');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return PaymentProof.fromJson(data['proof'] ?? data);
        }
      }
    } catch (e) {
      print('Error getting proof: $e');
    }
    return null;
  }

  // ==================== ADMIN ====================

  /// Obtener todos los métodos de pago (admin)
  static Future<List<PaymentMethod>> getAdminPaymentMethods() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/methods');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final methodsList = data['methods'] ?? data['data'] ?? [];
          return (methodsList as List)
              .map((m) => PaymentMethod.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('Error getting admin payment methods: $e');
    }
    return [];
  }

  /// Crear método de pago (admin)
  static Future<Map<String, dynamic>> createPaymentMethod({
    required String bankName,
    required String accountType,
    required String accountNumber,
    required String accountHolderName,
    required String accountHolderCi,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/methods');
      final body = json.encode({
        'bank_name': bankName,
        'account_type': accountType,
        'account_number': accountNumber,
        'account_holder_name': accountHolderName,
        'account_holder_ci': accountHolderCi,
      });

      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Método creado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error creando método'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Editar método de pago (admin)
  static Future<Map<String, dynamic>> updatePaymentMethod(
    int methodId, {
    String? bankName,
    String? accountType,
    String? accountNumber,
    String? accountHolderName,
    String? accountHolderCi,
    bool? isActive,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/methods/$methodId');
      final body = json.encode({
        if (bankName != null) 'bank_name': bankName,
        if (accountType != null) 'account_type': accountType,
        if (accountNumber != null) 'account_number': accountNumber,
        if (accountHolderName != null) 'account_holder_name': accountHolderName,
        if (accountHolderCi != null) 'account_holder_ci': accountHolderCi,
        if (isActive != null) 'is_active': isActive,
      });

      final res = await http.put(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Método actualizado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error actualizando método'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Eliminar método de pago (admin)
  static Future<Map<String, dynamic>> deletePaymentMethod(int methodId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/methods/$methodId');
      final res = await http.delete(uri, headers: _authHeaders(token)).timeout(_timeout);
      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Método eliminado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error eliminando método'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Obtener todos los comprobantes (admin)
  static Future<List<PaymentProof>> getAdminProofs() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/proofs');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final proofsList = data['proofs'] ?? data['data'] ?? [];
          return (proofsList as List)
              .map((p) => PaymentProof.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('Error getting admin proofs: $e');
    }
    return [];
  }

  /// Verificar comprobante (admin)
  static Future<Map<String, dynamic>> verifyProof(
    int proofId, {
    required bool verified,
    String? rejectionReason,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/proofs/$proofId/verify');
      final body = json.encode({
        'verified': verified,
        if (!verified && rejectionReason != null) 'rejection_reason': rejectionReason,
      });

      final res = await http.post(uri, headers: _authHeaders(token), body: body).timeout(_timeout);
      final data = json.decode(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Comprobante actualizado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error verificando comprobante'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Obtener estadísticas de pagos (admin)
  static Future<PaymentStats?> getPaymentStats() async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/stats');
      final res = await http.get(uri, headers: _authHeaders(token)).timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return PaymentStats.fromJson(data);
        }
      }
    } catch (e) {
      print('Error getting payment stats: $e');
    }
    return null;
  }

  /// Aceptar/Verificar método de pago de usuario (admin)
  static Future<Map<String, dynamic>> approvePaymentMethod(int methodId) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${Enviroments.apiurl}/api/payment/admin/methods/$methodId/approve');
      final res = await http.post(uri, headers: _authHeaders(token), body: json.encode({})).timeout(_timeout);
      final data = json.decode(res.body);

      if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Método de pago aceptado'};
      }
      return {'success': false, 'error': data['error'] ?? 'Error aceptando método de pago'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}