/// Modelos para pagos y comprobantes

/// Método de pago
class PaymentMethod {
  final int id;
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String accountHolderName;
  final String accountHolderCi;
  final bool isActive;
  final DateTime? createdAt;

  PaymentMethod({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.accountHolderName,
    required this.accountHolderCi,
    required this.isActive,
    this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    // Usar account_number o account_number_masked (sin máscara)
    String accountNum = json['account_number'] ?? json['account_number_masked'] ?? '';

    return PaymentMethod(
      id: json['id'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountType: json['account_type'] ?? '',
      accountNumber: accountNum,
      accountHolderName: json['account_holder_name'] ?? '',
      accountHolderCi: json['account_holder_ci'] ?? '',
      isActive: _toBool(json['is_active']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'bank_name': bankName,
    'account_type': accountType,
    'account_number': accountNumber,
    'account_holder_name': accountHolderName,
    'account_holder_ci': accountHolderCi,
    'is_active': isActive,
  };

  String get displayName => '$bankName - $accountHolderName';
  String get maskedAccount => accountNumber.length > 4 
      ? '**** ${accountNumber.substring(accountNumber.length - 4)}'
      : accountNumber;
}

/// Comprobante de pago
class PaymentProof {
  final int id;
  final int userId;
  final String email;
  final double amount;
  final String status; // pending, verified, rejected
  final String bankName;
  final String accountType;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  PaymentProof({
    required this.id,
    required this.userId,
    required this.email,
    required this.amount,
    required this.status,
    required this.bankName,
    required this.accountType,
    required this.createdAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  factory PaymentProof.fromJson(Map<String, dynamic> json) {
    return PaymentProof(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      email: json['email'] ?? 'desconocido@example.com',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
      bankName: json['bank_name'] ?? 'Desconocido',
      accountType: json['account_type'] ?? 'desconocido',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      rejectionReason: json['rejection_reason'],
    );
  }

  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending';

  String get statusDisplay {
    switch (status) {
      case 'verified':
        return 'Verificado';
      case 'rejected':
        return 'Rechazado';
      case 'pending':
      default:
        return 'Pendiente';
    }
  }

  String get userName => email.split('@').first.toUpperCase();
  String get methodName => bankName.toUpperCase();
}

/// Estadísticas de pagos
class PaymentStats {
  final int totalProofs;
  final int verifiedProofs;
  final int pendingProofs;
  final int rejectedProofs;
  final double totalAmount;
  final double verifiedAmount;

  PaymentStats({
    required this.totalProofs,
    required this.verifiedProofs,
    required this.pendingProofs,
    required this.rejectedProofs,
    required this.totalAmount,
    required this.verifiedAmount,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalProofs: json['total_proofs'] ?? 0,
      verifiedProofs: json['verified_proofs'] ?? 0,
      pendingProofs: json['pending_proofs'] ?? 0,
      rejectedProofs: json['rejected_proofs'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      verifiedAmount: (json['verified_amount'] ?? 0).toDouble(),
    );
  }
}

/// Respuesta completa de métodos de pago
class PaymentMethodsResponse {
  final bool success;
  final List<PaymentMethod> methods;
  final int count;

  PaymentMethodsResponse({
    required this.success,
    required this.methods,
    required this.count,
  });

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) {
    final methodsList = json['methods'] ?? [];
    return PaymentMethodsResponse(
      success: json['success'] ?? false,
      methods: (methodsList as List)
          .map((m) => PaymentMethod.fromJson(m as Map<String, dynamic>))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}
