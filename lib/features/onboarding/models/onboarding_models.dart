class OnboardingStatus {
  final bool completado;

  const OnboardingStatus({required this.completado});

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(completado: json['completado'] == true);
  }
}

class OnboardingQuestion {
  final String id;
  final String texto;
  final String categoria;
  final String escala;

  const OnboardingQuestion({
    required this.id,
    required this.texto,
    required this.categoria,
    required this.escala,
  });

  factory OnboardingQuestion.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestion(
      id: json['id']?.toString() ?? '',
      texto: json['texto']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'bienestar_general',
      escala: json['escala']?.toString() ?? '0-4',
    );
  }
}

class OnboardingSurvey {
  final int encuestaId;
  final String titulo;
  final bool completado;
  final List<OnboardingQuestion> preguntas;

  const OnboardingSurvey({
    required this.encuestaId,
    required this.titulo,
    required this.completado,
    required this.preguntas,
  });

  factory OnboardingSurvey.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['preguntas'];
    return OnboardingSurvey(
      encuestaId: (json['encuesta_id'] as num?)?.toInt() ?? 0,
      titulo: json['titulo']?.toString() ?? 'Encuesta Inicial de Bienestar',
      completado: json['completado'] == true,
      preguntas: rawQuestions is List
          ? rawQuestions
                .whereType<Map>()
                .map(
                  (item) => OnboardingQuestion.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (question) =>
                      question.id.isNotEmpty && question.texto.isNotEmpty,
                )
                .toList()
          : const [],
    );
  }
}
