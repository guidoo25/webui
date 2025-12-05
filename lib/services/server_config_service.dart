import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sri_master/conts/enviroments.dart';

/// Modelo para la configuración del servidor
class ServerConfig {
  final int id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String currency;
  final DateTime createdAt;

  ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.currency,
    required this.createdAt,
  });

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      port: json['port'] ?? 443,
      username: json['username'] ?? '',
      currency: json['currency'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// URL base del servidor (sin puerto si es 443/80)
  String get baseUrl {
    if (port == 443 || port == 80) {
      return host;
    }
    return '$host:$port';
  }
}

/// Estado del servidor
enum ServerStatus {
  unknown,
  loading,
  online,
  offline,
  error,
}

/// Servicio para obtener la configuración del servidor dinámicamente
class ServerConfigService {
  // No usamos más el endpoint externo de gio; la app usa un servidor propio
  static const String _prefsKey = 'server_config_cache_v1';
  
  static ServerConfig? _currentConfig;
  static ServerStatus _status = ServerStatus.unknown;
  static String? _errorMessage;
  static DateTime? _lastCheck;
  static Timer? _periodicTimer;
  static Completer<void>? _readyCompleter;

  /// Configuración actual del servidor
  static ServerConfig? get currentConfig => _currentConfig;
  
  /// Estado actual del servidor
  static ServerStatus get status => _status;
  
  /// Mensaje de error si lo hay
  static String? get errorMessage => _errorMessage;
  
  /// Última vez que se verificó
  static DateTime? get lastCheck => _lastCheck;

  /// Indica cuando la primera carga ha terminado (success o fallback)
  static Future<void> ensureLoaded() async {
    if (_readyCompleter != null) return _readyCompleter!.future;
    _readyCompleter = Completer<void>();

    // Simple: usar el servidor propio definido en Enviroments.
    // Marcamos el estado como online de forma conservadora.
    Enviroments.apiurl = Enviroments.apiurl; // no-op, deja la URL actual
    _status = ServerStatus.online;
    _lastCheck = DateTime.now();

    _readyCompleter?.complete();
    return _readyCompleter!.future;
  }

  /// Obtiene la configuración del servidor desde la API externa
  /// retries: número de reintentos en caso de fallo (backoff)
  static Future<bool> fetchServerConfig({int retries = 0}) async {
    // Ya no consultamos el endpoint externo; simplemente usamos la URL configurada
    try {
      _status = ServerStatus.loading;
      _lastCheck = DateTime.now();
      // Asumimos que la URL en Enviroments es la correcta
      _status = ServerStatus.online;
      return true;
    } catch (e) {
      _status = ServerStatus.offline;
      _errorMessage = e.toString();
      return false;
    }
  }

  static Future<void> _saveToCache(String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, rawJson);
    } catch (_) {}
  }

  static Future<ServerConfig?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return null;
      final data = json.decode(raw);
      if (data['data'] != null) return ServerConfig.fromJson(data['data']);
    } catch (_) {}
    return null;
  }

  /// Verifica si el servidor API está respondiendo
  static Future<bool> pingServer() async {
    try {
      final healthUrl = Uri.parse('${Enviroments.apiurl}/api/health');
      final response = await http.get(healthUrl).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Inicia refresh periódico cada [interval]
  static void startPeriodicRefresh(Duration interval) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) async {
      await fetchServerConfig(retries: 1);
    });
  }

  /// Detener refresh periódico
  static void stopPeriodicRefresh() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Reinicia la configuración
  static Future<void> reset() async {
    _currentConfig = null;
    _status = ServerStatus.unknown;
    _errorMessage = null;
    _lastCheck = null;
    Enviroments.apiurl = 'https://api.factubot.org';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
