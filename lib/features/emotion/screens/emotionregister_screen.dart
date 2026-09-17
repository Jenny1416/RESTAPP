// emotionregister_screen.dart (Preguntas de evaluación emocional)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/emotion_service.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/features/emotion/utils/emotion_calculator.dart';

class EmotionRegisterScreen extends StatefulWidget {
  const EmotionRegisterScreen({super.key});

  @override
  State<EmotionRegisterScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<EmotionRegisterScreen> {
  final EmotionService _emotionService = EmotionService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _preguntas = [];
  final Map<int, int> _opcionSeleccionadaPorPregunta =
      {}; // preguntaId -> opcionId

  final List<String> _facesAssets = const [
    'assets/images/sadrest.jpg',
    'assets/images/yellowrest.jpg',
    'assets/images/normalrest.jpg',
    'assets/images/goodrest.jpg',
    'assets/images/statesuperexcellent.png', // Cambio: nueva imagen para excelente
  ];

  // Etiquetas para las emociones
  final List<String> _emotionLabels = const [
    'Muy mal',
    'Mal',
    'Normal',
    'Bien',
    'Excelente',
  ];

  @override
  void initState() {
    super.initState();
    _cargarPreguntas();
  }

  Future<void> _cargarPreguntas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Obtener preguntas aleatorias del backend
      final preguntasData = await _emotionService.fetchPreguntas();
      setState(() {
        _preguntas = List<Map<String, dynamic>>.from(
          preguntasData.map(
            (p) => p is Map ? Map<String, dynamic>.from(p) : {},
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarRespuestas() async {
    if (_preguntas.isEmpty) return;

    final respuestas = <Map<String, int>>[];
    for (final q in _preguntas) {
      final int? preguntaId = q['id'] is int ? q['id'] as int : null;
      if (preguntaId == null) continue;
      final int? opcionId = _opcionSeleccionadaPorPregunta[preguntaId];
      if (opcionId == null) continue;
      respuestas.add({'pregunta_id': preguntaId, 'opcion_id': opcionId});
    }

    if (respuestas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una respuesta.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _emotionService.enviarRegistroEmocional(respuestas: respuestas);

      // Actualizar fecha del último test completado
      UserSession.lastTestDate = DateTime.now();
      await UserSession.persist();

      if (!mounted) return;
      final resultado = EmotionCalculator.calcularEstado(
        preguntas: _preguntas,
        opcionSeleccionadaPorPregunta: _opcionSeleccionadaPorPregunta,
      );
      // Navegar directo al semáforo emocional
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.trafficLight,
        arguments: resultado,
      );
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('CONFLICT_ERROR')) {
        // El test de hoy ya fue completado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya has completado el test emocional de hoy.'),
          ),
        );
        UserSession.lastTestDate = DateTime.now();
        await UserSession.persist();

        // Redirigir a MainApp
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.mainApp);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header con logo y título
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Logo igual al del chat
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF7DFDFE),
                          Color(0xFF4ECDC4),
                          Color(0xFF00B4D8),
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF4ECDC4), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4ECDC4).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/normalrest.jpg',
                        width: 80.w,
                        height: 80.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  // Título
                  Expanded(
                    child: Text(
                      "¡Cuéntame\nsobre tu día¡",
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 35.sp,
                        height: 0.9,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              Color(0xFF7DFDFE), // Celeste
                              Color(0xFF2196F3), // Azul
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(Rect.fromLTWH(0, 0, 250, 60)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF2196F3), width: 2),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorContent()
                    : _buildPreguntasContent(context),
              ),
            ),

            // Botón guardar
            Container(
              margin: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2196F3), // Azul izquierdo
                        Color(0xFF3973D1), // Azul derecho (más oscuro)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: TextButton(
                    onPressed: _isLoading ? null : _guardarRespuestas,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      "GUARDAR",
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 30.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No pudimos cargar las preguntas.',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.red),
              ),
            ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: _cargarPreguntas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntasContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            "Test Personal Diario",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontFamily: 'Freeman',
            ),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _preguntas.map((q) {
                final int? id = (q['id'] as int?);
                if (id == null) return const SizedBox.shrink();
                final String textoPregunta = (q['texto'] ?? q['pregunta'] ?? '')
                    .toString();
                final String categoria = (q['categoria'] ?? '').toString();
                final List<dynamic> opciones = (q['opciones'] is List)
                    ? q['opciones'] as List
                    : const [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoria.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF5CCFC0,
                            ).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _dimensionLabel(categoria),
                            style: const TextStyle(
                              color: Color(0xFF167E76),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          textoPregunta,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onPrimaryContainer,
                            fontFamily: 'Freeman',
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final int count = opciones.length.clamp(
                            0,
                            _facesAssets.length,
                          );
                          final double maxFaceSize = 48;
                          final double spacing = 8;
                          final double borderWidth = 3 * 2;
                          final double paddingSize = 4 * 2;
                          final double available = constraints.maxWidth;
                          final double idealTotal =
                              count *
                                  (maxFaceSize + borderWidth + paddingSize) +
                              (count - 1) * spacing;
                          final double faceSize = idealTotal > available
                              ? ((available - (count - 1) * spacing) / count -
                                        borderWidth -
                                        paddingSize)
                                    .clamp(24, maxFaceSize)
                              : maxFaceSize;

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(count, (index) {
                                  final dynamic opcion = opciones[index];
                                  final int? opcionId =
                                      (opcion is Map && opcion['id'] is int)
                                      ? opcion['id'] as int
                                      : null;
                                  if (opcionId == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final bool seleccionado =
                                      _opcionSeleccionadaPorPregunta[id] ==
                                      opcionId;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _opcionSeleccionadaPorPregunta[id] =
                                            opcionId;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: seleccionado
                                              ? const Color(0xFFFFC107)
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          _facesAssets[index.clamp(
                                            0,
                                            _facesAssets.length - 1,
                                          )],
                                          width: faceSize,
                                          height: faceSize,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: 8.h),
                              // Agregar etiquetas de emociones
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(count, (index) {
                                  final dynamic opcion = opciones[index];
                                  final String nombreOpcion =
                                      (opcion is Map &&
                                          opcion['nombre'] is String)
                                      ? opcion['nombre'] as String
                                      : _emotionLabels[index.clamp(
                                          0,
                                          _emotionLabels.length - 1,
                                        )];
                                  return SizedBox(
                                    width: faceSize + 8,
                                    child: Text(
                                      nombreOpcion,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                        fontFamily: 'Freeman',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _dimensionLabel(String value) {
    const labels = {
      'ansiedad': 'Ansiedad',
      'estres_academico': 'Estrés académico',
      'humor_depresivo': 'Estado de ánimo',
      'sueno': 'Sueño',
      'relaciones_sociales': 'Relaciones sociales',
      'autoestima_autocuidado': 'Autoestima y autocuidado',
      'energia_motivacion': 'Energía y motivación',
    };
    return labels[value] ?? value.replaceAll('_', ' ');
  }
}
