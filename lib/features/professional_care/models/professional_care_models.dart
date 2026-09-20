class Psychologist {
  const Psychologist({
    required this.id,
    required this.firstNames,
    required this.lastNames,
    this.specialty,
    this.city,
    this.language,
  });

  final int id;
  final String firstNames;
  final String lastNames;
  final String? specialty;
  final String? city;
  final String? language;

  String get fullName => '$firstNames $lastNames'.trim();

  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'PS';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  factory Psychologist.fromJson(Map<String, dynamic> json) {
    return Psychologist(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstNames: (json['nombres'] ?? '').toString().trim(),
      lastNames: (json['apellidos'] ?? '').toString().trim(),
      specialty: _optionalText(json['especialidad_psicologo']),
      city: _optionalText(json['ciudad']),
      language: _optionalText(json['idioma']),
    );
  }
}

enum AssignmentStatus { pending, approved, rejected, finished, unknown }

class CareAssignment {
  const CareAssignment({
    required this.id,
    required this.studentId,
    required this.psychologistId,
    required this.status,
    this.message,
    this.requestedAt,
    this.processedAt,
    this.finishedAt,
  });

  final int id;
  final int? studentId;
  final int? psychologistId;
  final AssignmentStatus status;
  final String? message;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final DateTime? finishedAt;

  bool get isPending => status == AssignmentStatus.pending;
  bool get isApproved => status == AssignmentStatus.approved;
  bool get canBeClosed => isPending || isApproved;

  factory CareAssignment.fromJson(Map<String, dynamic> json) {
    return CareAssignment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      studentId: (json['estudiante_id'] as num?)?.toInt(),
      psychologistId: (json['psicologo_id'] as num?)?.toInt(),
      status: _assignmentStatus((json['estado'] ?? '').toString()),
      message: _optionalText(json['mensaje']),
      requestedAt: DateTime.tryParse((json['solicitado_en'] ?? '').toString()),
      processedAt: DateTime.tryParse((json['procesado_en'] ?? '').toString()),
      finishedAt: DateTime.tryParse((json['finalizado_en'] ?? '').toString()),
    );
  }
}

class ProfessionalChat {
  const ProfessionalChat({
    required this.id,
    required this.studentId,
    required this.psychologistId,
    required this.startedAt,
    required this.lastActivity,
    required this.isActive,
    required this.isAi,
  });

  final int id;
  final int? studentId;
  final int? psychologistId;
  final DateTime startedAt;
  final DateTime lastActivity;
  final bool isActive;
  final bool isAi;

  factory ProfessionalChat.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ProfessionalChat(
      id: (json['id'] as num?)?.toInt() ?? 0,
      studentId: (json['estudiante_id'] as num?)?.toInt(),
      psychologistId: (json['psicologo_id'] as num?)?.toInt(),
      startedAt:
          DateTime.tryParse((json['iniciado_en'] ?? '').toString()) ?? now,
      lastActivity:
          DateTime.tryParse((json['ultima_actividad'] ?? '').toString()) ?? now,
      isActive: json['is_active'] == true,
      isAi: json['isSendByAi'] == true,
    );
  }
}

class ProfessionalMessage {
  const ProfessionalMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.sentAt,
  });

  final int id;
  final int? userId;
  final String text;
  final DateTime sentAt;

  factory ProfessionalMessage.fromJson(Map<String, dynamic> json) {
    return ProfessionalMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['usuario_id'] as num?)?.toInt(),
      text: (json['mensaje'] ?? '').toString(),
      sentAt:
          DateTime.tryParse((json['enviado_en'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

AssignmentStatus _assignmentStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'pendiente':
      return AssignmentStatus.pending;
    case 'aprobado':
      return AssignmentStatus.approved;
    case 'rechazado':
      return AssignmentStatus.rejected;
    case 'finalizado':
      return AssignmentStatus.finished;
    default:
      return AssignmentStatus.unknown;
  }
}

String? _optionalText(dynamic raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}
