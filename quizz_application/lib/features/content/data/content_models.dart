enum QuestionDifficulty {
  easy(1, 'Fácil'),
  medium(2, 'Media'),
  hard(3, 'Difícil');

  const QuestionDifficulty(this.apiValue, this.label);

  final int apiValue;
  final String label;

  factory QuestionDifficulty.fromJson(Object? value) {
    if (value is int) {
      return QuestionDifficulty.values.firstWhere(
        (difficulty) => difficulty.apiValue == value,
        orElse: () => QuestionDifficulty.medium,
      );
    }
    final normalized = value?.toString().toLowerCase();
    return switch (normalized) {
      'easy' || '1' => QuestionDifficulty.easy,
      'hard' || '3' => QuestionDifficulty.hard,
      _ => QuestionDifficulty.medium,
    };
  }
}

class SubjectModel {
  const SubjectModel({required this.id, required this.name, this.description});
  final String id;
  final String name;
  final String? description;

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class SchoolModel {
  const SchoolModel({required this.id, required this.name, this.city});
  final String id;
  final String name;
  final String? city;

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString(),
    );
  }
}

class QuestionOptionModel {
  const QuestionOptionModel({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
  final String id;
  final String text;
  final bool isCorrect;

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
    );
  }
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.text,
    required this.justification,
    required this.difficulty,
    required this.subjectId,
    required this.subjectName,
    required this.createdByUserId,
    required this.options,
  });

  final String id;
  final String text;
  final String justification;
  final QuestionDifficulty difficulty;
  final String subjectId;
  final String subjectName;
  final String createdByUserId;
  final List<QuestionOptionModel> options;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      justification: json['justification']?.toString() ?? '',
      difficulty: QuestionDifficulty.fromJson(json['difficulty']),
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      createdByUserId: json['createdByUserId']?.toString() ?? '',
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map((option) => QuestionOptionModel.fromJson(
                      Map<String, dynamic>.from(option),
                    ))
                .toList(growable: false)
          : const [],
    );
  }
}

class QuestionOptionDraft {
  const QuestionOptionDraft({required this.text, required this.isCorrect});
  final String text;
  final bool isCorrect;
  Map<String, dynamic> toJson() => {'text': text, 'isCorrect': isCorrect};
}

class QuestionDraft {
  const QuestionDraft({
    required this.text,
    required this.justification,
    required this.difficulty,
    required this.subjectId,
    required this.options,
  });
  final String text;
  final String justification;
  final QuestionDifficulty difficulty;
  final String subjectId;
  final List<QuestionOptionDraft> options;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'justification': justification,
      'difficulty': difficulty.apiValue,
      'subjectId': subjectId,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

/// Modelo de un código de invitación institucional.
class InvitationCodeModel {
  const InvitationCodeModel({
    required this.id,
    required this.code,
    required this.institutionId,
    required this.institutionName,
    required this.maxUses,
    required this.uses,
    required this.isActive,
    required this.isUsable,
    required this.createdAtUtc,
    this.expiresAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String code;
  final String institutionId;
  final String institutionName;
  final int maxUses;
  final int uses;
  final DateTime? expiresAtUtc;
  final bool isActive;
  final bool isUsable;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  bool get isUnlimited => maxUses < 0;
  int get remainingUses => isUnlimited ? -1 : (maxUses - uses).clamp(0, maxUses);

  String get usesLabel {
    if (isUnlimited) return '$uses usos · ilimitado';
    return '$uses / $maxUses usos';
  }

  factory InvitationCodeModel.fromJson(Map<String, dynamic> json) {
    return InvitationCodeModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      institutionId: json['institutionId']?.toString() ?? '',
      institutionName: json['institutionName']?.toString() ?? '',
      maxUses: (json['maxUses'] as num?)?.toInt() ?? -1,
      uses: (json['uses'] as num?)?.toInt() ?? 0,
      expiresAtUtc: _parseDate(json['expiresAtUtc']),
      isActive: json['isActive'] == true,
      isUsable: json['isUsable'] == true,
      createdAtUtc: _parseDate(json['createdAtUtc']) ?? DateTime.now(),
      updatedAtUtc: _parseDate(json['updatedAtUtc']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toUtc();
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// PLANES Y SUSCRIPCIONES
// ─────────────────────────────────────────────────────────────

/// Plan del catálogo (FREE, STANDARD, SEMESTRAL, INSTITUTIONAL).
class PlanModel {
  const PlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.target,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.displayOrder,
    this.description,
  });

  final String id;
  final String code;
  final String name;
  final String? description;

  /// "Particular" o "Institutional"
  final String target;
  final int durationDays;
  final double price;
  final String currency;
  final bool isActive;
  final int displayOrder;

  bool get isFree => price == 0;
  bool get isParticular => target == 'Particular';
  bool get isInstitutional => target == 'Institutional';

  /// Precio formateado en pesos colombianos. Ej: "$29.900 COP" o "Gratis".
  String get priceLabel {
    if (isFree) return 'Gratis';
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '\$$formatted $currency';
  }

  /// Duración legible. Ej: "7 días", "1 mes", "6 meses", "1 año".
  String get durationLabel {
    if (durationDays == 7) return '7 días';
    if (durationDays == 30) return '1 mes';
    if (durationDays == 90) return '3 meses';
    if (durationDays == 180) return '6 meses';
    if (durationDays == 365) return '1 año';
    return '$durationDays días';
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      target: json['target']?.toString() ?? 'Particular',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'COP',
      isActive: json['isActive'] == true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Suscripción activa (o pasada) del usuario o su institución.
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.ownerType,
    required this.planId,
    required this.planCode,
    required this.planName,
    required this.status,
    required this.startedAtUtc,
    required this.expiresAtUtc,
    required this.autoRenew,
    required this.isCurrentlyActive,
    required this.daysRemaining,
    this.userId,
    this.institutionId,
    this.institutionName,
    this.cancelledAtUtc,
  });

  final String id;

  /// "Particular" o "Institutional"
  final String ownerType;
  final String? userId;
  final String? institutionId;
  final String? institutionName;
  final String planId;
  final String planCode;
  final String planName;

  /// "Pending", "Active", "Expired", "Cancelled", "PastDue"
  final String status;
  final DateTime startedAtUtc;
  final DateTime expiresAtUtc;
  final DateTime? cancelledAtUtc;
  final bool autoRenew;
  final bool isCurrentlyActive;
  final int daysRemaining;

  bool get isParticular => ownerType == 'Particular';
  bool get isInstitutional => ownerType == 'Institutional';
  bool get isExpired => status == 'Expired' || daysRemaining < 0;
  bool get isCancelled => status == 'Cancelled';
  bool get isPending => status == 'Pending';

  /// Etiqueta legible del estado.
  String get statusLabel {
    return switch (status) {
      'Pending' => 'Pendiente',
      'Active' => 'Activa',
      'Expired' => 'Expirada',
      'Cancelled' => 'Cancelada',
      'PastDue' => 'Pago pendiente',
      _ => status,
    };
  }

  /// Texto de días restantes o vencimiento.
  String get remainingLabel {
    if (daysRemaining < 0) {
      final days = daysRemaining.abs();
      return 'Venció hace $days ${days == 1 ? "día" : "días"}';
    }
    if (daysRemaining == 0) return 'Vence hoy';
    return '$daysRemaining ${daysRemaining == 1 ? "día restante" : "días restantes"}';
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id']?.toString() ?? '',
      ownerType: json['ownerType']?.toString() ?? 'Particular',
      userId: json['userId']?.toString(),
      institutionId: json['institutionId']?.toString(),
      institutionName: json['institutionName']?.toString(),
      planId: json['planId']?.toString() ?? '',
      planCode: json['planCode']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      startedAtUtc: _parseDate(json['startedAtUtc']) ?? DateTime.now(),
      expiresAtUtc: _parseDate(json['expiresAtUtc']) ?? DateTime.now(),
      cancelledAtUtc: _parseDate(json['cancelledAtUtc']),
      autoRenew: json['autoRenew'] == true,
      isCurrentlyActive: json['isCurrentlyActive'] == true,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toUtc();
    } catch (_) {
      return null;
    }
  }
}