import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sri_master/conts/enviroments.dart';

class SubscriptionService {
  /// Crea un plan (admin)
  static Future<bool> createPlan({
    required String token,
    required String name,
    required String code,
    required double price,
    required int maxSriCredentials,
    required int maxDownloadsMonth,
    required int maxConcurrentTasks,
    String? description,
  }) async {
    final uri = Uri.parse('${Enviroments.apiurl}/api/subscriptions/admin/plans');
    final body = json.encode({
      'name': name,
      'code': code,
      'price': price,
      'max_sri_credentials': maxSriCredentials,
      'max_downloads_month': maxDownloadsMonth,
      'max_concurrent_tasks': maxConcurrentTasks,
      'description': description ?? '',
    });

    try {
      final res = await http.post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body).timeout(const Duration(seconds: 10));

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  /// Asigna plan a usuario (admin)
  static Future<bool> assignPlan({
    required String token,
    required int userId,
    required int planId,
    required String expiresAt,
    required String paymentMethod,
  }) async {
    final uri = Uri.parse('${Enviroments.apiurl}/api/subscriptions/admin/assign');
    final body = json.encode({
      'user_id': userId,
      'plan_id': planId,
      'expires_at': expiresAt,
      'payment_method': paymentMethod,
    });

    try {
      final res = await http.post(uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body).timeout(const Duration(seconds: 10));

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
}
