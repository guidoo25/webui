/// Modelos para el panel de administración

/// Usuario del sistema
class AdminUser {
  final int id;
  final String email;
  final String? nombre;
  final bool isAdmin;
  final bool isActive;
  final DateTime? createdAt;
  final int? planId;
  final String? planName;
  final DateTime? subscriptionExpiresAt;
  final int credentialsCount;
  final int downloadsThisMonth;

  AdminUser({
    required this.id,
    required this.email,
    this.nombre,
    required this.isAdmin,
    required this.isActive,
    this.createdAt,
    this.planId,
    this.planName,
    this.subscriptionExpiresAt,
    this.credentialsCount = 0,
    this.downloadsThisMonth = 0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    // Helper para convertir int/bool a bool
    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return AdminUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? json['username'] ?? '',
      nombre: json['nombre'] ?? json['name'],
      isAdmin: _toBool(json['is_admin']),
      isActive: _toBool(json['is_active']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      planId: json['plan_id'],
      planName: json['plan_name'] ?? json['subscription']?['plan_name'],
      subscriptionExpiresAt: json['subscription_expires_at'] != null 
          ? DateTime.tryParse(json['subscription_expires_at'].toString())
          : json['subscription']?['expires_at'] != null
              ? DateTime.tryParse(json['subscription']['expires_at'].toString())
              : null,
      credentialsCount: json['credentials_count'] ?? json['sri_credentials_count'] ?? 0,
      downloadsThisMonth: json['downloads_this_month'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nombre': nombre,
    'is_admin': isAdmin,
    'is_active': isActive,
  };

  bool get hasActiveSubscription {
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  String get displayName => nombre ?? email;
}

/// Credencial SRI del usuario
class SriCredential {
  final int id;
  final String ruc;
  final String? ciAdicional;
  final String? passwordSri;
  final String? descripcion;
  final bool isActive;
  final DateTime? createdAt;
  final int? userId;

  SriCredential({
    required this.id,
    required this.ruc,
    this.ciAdicional,
    this.passwordSri,
    this.descripcion,
    required this.isActive,
    this.createdAt,
    this.userId,
  });

  factory SriCredential.fromJson(Map<String, dynamic> json) {
    // Helper para convertir int/bool a bool
    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return SriCredential(
      id: json['id'] ?? 0,
      ruc: json['ruc'] ?? '',
      ciAdicional: json['ci_adicional'],
      passwordSri: json['password_sri'] ?? json['password'],
      descripcion: json['descripcion'],
      isActive: _toBool(json['is_active']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ruc': ruc,
    'ci_adicional': ciAdicional ?? '',
    'password_sri': passwordSri,
    'descripcion': descripcion,
  };

  String get displayName => descripcion ?? ruc;
}

/// Plan de suscripción
class SubscriptionPlan {
  final int id;
  final String name;
  final String code;
  final String? description;
  final double price;
  final int maxSriCredentials;
  final int maxDownloadsMonth;
  final int maxConcurrentTasks;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.price,
    required this.maxSriCredentials,
    required this.maxDownloadsMonth,
    required this.maxConcurrentTasks,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // Helper para convertir int/bool a bool
    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return SubscriptionPlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      maxSriCredentials: json['max_sri_credentials'] ?? 1,
      maxDownloadsMonth: json['max_downloads_month'] ?? 50,
      maxConcurrentTasks: json['max_concurrent_tasks'] ?? 1,
      isActive: _toBool(json['is_active']),
    );
  }
}

/// Suscripción del usuario
class UserSubscription {
  final int id;
  final int userId;
  final int planId;
  final String planName;
  final String planCode;
  final DateTime? startDate;
  final DateTime? expiresAt;
  final bool isActive;
  final int maxCredentials;
  final int maxDownloads;
  final int usedCredentials;
  final int usedDownloads;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.planCode,
    this.startDate,
    this.expiresAt,
    required this.isActive,
    required this.maxCredentials,
    required this.maxDownloads,
    this.usedCredentials = 0,
    this.usedDownloads = 0,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    // Helper para convertir int/bool a bool
    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    // Obtener datos del plan (puede venir en 'plan' o en el nivel raíz)
    final planData = json['plan'] ?? json;
    
    return UserSubscription(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      planId: json['plan_id'] ?? planData['id'] ?? 0,
      planName: planData['name'] ?? json['plan_name'] ?? 'Sin plan',
      planCode: planData['code'] ?? json['plan_code'] ?? '',
      startDate: json['started_at'] != null 
          ? DateTime.tryParse(json['started_at'].toString()) 
          : json['start_date'] != null
              ? DateTime.tryParse(json['start_date'].toString())
              : null,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at'].toString()) 
          : null,
      isActive: _toBool(json['status'] == 'active' ? true : json['is_active']),
      maxCredentials: planData['max_sri_credentials'] ?? json['max_credentials'] ?? 1,
      maxDownloads: planData['max_downloads_month'] ?? json['max_downloads'] ?? 50,
      usedCredentials: json['credentials_count'] ?? json['used_credentials'] ?? 0,
      usedDownloads: json['downloads_this_month'] ?? json['used_downloads'] ?? 0,
    );
  }

  bool get hasExpired {
    if (expiresAt == null) return true;
    return expiresAt!.isBefore(DateTime.now());
  }

  int get daysRemaining {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  double get credentialsUsagePercent => 
      maxCredentials > 0 ? (usedCredentials / maxCredentials) * 100 : 0;
  
  double get downloadsUsagePercent => 
      maxDownloads > 0 ? (usedDownloads / maxDownloads) * 100 : 0;
}

/// Carpeta de comprobantes
class ComprobanteFolder {
  final String folder;
  final String ruc;
  final String? descripcion;
  final String year;
  final String month;
  final int totalFiles;
  final DateTime? lastModified;

  ComprobanteFolder({
    required this.folder,
    required this.ruc,
    this.descripcion,
    required this.year,
    required this.month,
    required this.totalFiles,
    this.lastModified,
  });

  factory ComprobanteFolder.fromJson(Map<String, dynamic> json) {
    return ComprobanteFolder(
      folder: json['folder'] ?? '',
      ruc: json['ruc'] ?? json['username'] ?? '',
      descripcion: json['descripcion'],
      year: json['year']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      totalFiles: json['total_files'] ?? 0,
      lastModified: json['last_modified'] != null 
          ? DateTime.tryParse(json['last_modified'].toString()) 
          : null,
    );
  }

  String get displayName => descripcion ?? '$ruc - $year/$month';
  String get period => '$month $year';
}
