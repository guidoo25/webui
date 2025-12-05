import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sri_master/conts/enviroments.dart';

/// Modelo para representar una tarea en la cola
class QueueTask {
  final String taskId;
  final int? position;
  final String status;
  final String username;
  final String year;
  final String month;
  final String? type;
  final DateTime? createdAt;
  final TaskProgress? progress;

  QueueTask({
    required this.taskId,
    this.position,
    required this.status,
    required this.username,
    required this.year,
    required this.month,
    this.type,
    this.createdAt,
    this.progress,
  });

  factory QueueTask.fromJson(Map<String, dynamic> json) {
    return QueueTask(
      taskId: json['task_id'] ?? '',
      position: json['position'] is int ? json['position'] : null,
      status: json['status'] ?? 'unknown',
      username: json['username'] ?? '',
      year: json['year']?.toString() ?? '',
      month: json['month'] ?? '',
      type: json['type'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      progress: json['progress'] != null 
          ? TaskProgress.fromJson(json['progress']) 
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 'queued':
        return 'En cola';
      case 'processing':
        return 'Procesando';
      case 'completed':
        return 'Completado';
      case 'failed':
        return 'Error';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  bool get isActive => status == 'queued' || status == 'processing';
}

/// Modelo para el progreso de una tarea
class TaskProgress {
  final int total;
  final int downloaded;
  final double percentage;

  TaskProgress({
    required this.total,
    required this.downloaded,
    required this.percentage,
  });

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    return TaskProgress(
      total: json['total'] ?? 0,
      downloaded: json['downloaded'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

/// Respuesta al iniciar una descarga
class StartDownloadResponse {
  final bool success;
  final String message;
  final String taskId;
  final dynamic positionInQueue;
  final String status;
  final String username;
  final String year;
  final String month;

  StartDownloadResponse({
    required this.success,
    required this.message,
    required this.taskId,
    required this.positionInQueue,
    required this.status,
    required this.username,
    required this.year,
    required this.month,
  });

  factory StartDownloadResponse.fromJson(Map<String, dynamic> json) {
    return StartDownloadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      taskId: json['task_id'] ?? '',
      positionInQueue: json['position_in_queue'],
      status: json['status'] ?? '',
      username: json['username'] ?? '',
      year: json['year']?.toString() ?? '',
      month: json['month'] ?? '',
    );
  }

  String get positionText {
    if (positionInQueue is int) {
      return 'Posición #$positionInQueue';
    }
    return positionInQueue?.toString() ?? 'N/A';
  }
}

/// Servicio para gestionar la cola de descargas
class QueueService {
  static String get _baseUrl => Enviroments.apiurl;

  /// Iniciar una nueva descarga
  static Future<StartDownloadResponse> startDownload({
    required String username,
    required String password,
    required String year,
    required String month,
    String ciadicional = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sri-xmls'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'ciadicional': ciadicional,
          'year': year,
          'month': month,
        }),
      );

      final data = jsonDecode(response.body);
      return StartDownloadResponse.fromJson(data);
    } catch (e) {
      return StartDownloadResponse(
        success: false,
        message: 'Error de conexión: $e',
        taskId: '',
        positionInQueue: null,
        status: 'error',
        username: username,
        year: year,
        month: month,
      );
    }
  }

  /// Listar todas las tareas en cola
  static Future<List<QueueTask>> listQueue() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/queue/list'),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final tasks = data['tasks'] as List<dynamic>? ?? [];
        return tasks.map((t) => QueueTask.fromJson(t)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Listar tareas de un usuario específico
  static Future<List<QueueTask>> getUserQueue(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/queue/user/$username'),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final tasks = data['tasks'] as List<dynamic>? ?? [];
        return tasks.map((t) => QueueTask.fromJson(t)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtener estado detallado de una tarea
  static Future<QueueTask?> getTaskStatus(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/queue/status/$taskId'),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['task'] != null) {
        return QueueTask.fromJson(data['task']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cancelar una tarea en cola
  static Future<bool> cancelTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/queue/cancel/$taskId'),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
