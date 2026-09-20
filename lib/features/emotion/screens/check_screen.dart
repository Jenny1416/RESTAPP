import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/emotion_service.dart';
import 'package:rest/features/emotion/utils/emotion_calculator.dart';

const List<String> _nombresDias = [
  'LUN',
  'MAR',
  'MIÉ',
  'JUE',
  'VIE',
  'SÁB',
  'DOM',
];

class CheckScreen extends StatefulWidget {
  /// Promedio emocional del día actual (0-4). Se usa cuando viene del flujo de registro
  /// para mostrar la carita aunque el API aún no devuelva los datos.
  final double? promedioHoy;

  const CheckScreen({super.key, this.promedioHoy});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  final EmotionService _emotionService = EmotionService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _calendario = [];

  @override
  void initState() {
    super.initState();
    _cargarCalendario();
  }

  Future<void> _cargarCalendario() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hoy = DateTime.now();
      // Lunes a Domingo de la semana actual
      final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
      final domingo = lunes.add(const Duration(days: 6));
      final inicio = DateTime(lunes.year, lunes.month, lunes.day);
      final fin = DateTime(domingo.year, domingo.month, domingo.day);

      final datos = await _emotionService.fetchCalendarioEmocional(
        inicio: inicio,
        fin: fin,
      );

      if (!mounted) return;
      setState(() {
        _calendario = datos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 450.w),
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo principal
                  ClipOval(
                    child: Image.asset(
                      "assets/images/kingrest.jpg",
                      width: 200.w,
                      height: 200.w,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF4DD0E1), Color(0xFF26C6DA)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Text('😊', style: TextStyle(fontSize: 80.sp)),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 20.h),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFE91E63),
                        Color(0xFFFF5722),
                        Color(0xFFFF9800),
                        Color(0xFFFFEB3B),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      "¡Ok Listo!",
                      style: TextStyle(
                        fontSize: 48.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Contenedor del registro emocional
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9ADDFF),
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(color: Colors.black, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "REGISTRO EMOCIONAL",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF9800),
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.white,
                                offset: const Offset(1, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "¡GUARDADO!",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Text(
                          "HISTORIAL SEMANAL",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0277BD),
                            letterSpacing: 1.0,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 15.h),
                        _buildCalendarioContent(colorScheme),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  Container(
                    width: 200.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.r),
                      gradient: const RadialGradient(
                        colors: [Color(0xFF0BBDAC), Color(0xFF6110E8)],
                        center: Alignment.center,
                        radius: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0BBDAC).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.mainApp,
                        );
                      },
                      child: Text(
                        "LISTO",
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarioContent(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'No se pudo cargar el historial.',
              style: TextStyle(fontSize: 14.sp, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _cargarCalendario,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Mapa fecha -> promedio (YYYY-MM-DD normalizado)
    final Map<String, num> datosPorFecha = {};
    for (final item in _calendario) {
      final fechaStr = (item['fecha'] ?? item['dia'] ?? '').toString();
      if (fechaStr.isEmpty) continue;
      final fechaNorm = _normalizarFecha(fechaStr);
      if (fechaNorm == null) continue;
      final p = _parsePromedio(
        item['promedio'] ??
            item['promedio_emocional'] ??
            item['valor'] ??
            item['score'],
      );
      if (p != null) datosPorFecha[fechaNorm] = p;
    }

    // Si viene del flujo de registro, usar promedioHoy para hoy (asegura que se muestre la carita)
    final promedioHoy = widget.promedioHoy;
    if (promedioHoy != null) {
      final hoy = DateTime.now();
      final hoyStr = _formatFechaYyyyMmDd(hoy);
      datosPorFecha[hoyStr] = promedioHoy;
    }

    // Lunes a Domingo de la semana actual
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    final diasSemana = List.generate(7, (i) => lunes.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: diasSemana.map((fecha) {
            final fechaStr = _formatFechaYyyyMmDd(fecha);
            final diaNombre = _nombresDias[fecha.weekday - 1];
            final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
            final fechaNormalizada = DateTime(
              fecha.year,
              fecha.month,
              fecha.day,
            );
            final esFuturo = fechaNormalizada.isAfter(hoyNormalizado);
            final tieneDatos = datosPorFecha.containsKey(fechaStr);

            Widget icono;
            if (esFuturo) {
              icono = _buildPendienteIcon();
            } else if (tieneDatos) {
              final promedio = datosPorFecha[fechaStr]!;
              // Determinar estado emocional según el promedio
              final estado = _calcularEstadoDelPromedio(promedio);
              icono = _buildEstadoCircle(estado, promedio);
            } else {
              icono = _buildNoLlenoIcon();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDayLabel(diaNombre),
                  SizedBox(height: 6.h),
                  icono,
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Normaliza fecha del API a YYYY-MM-DD
  String? _normalizarFecha(String s) {
    if (s.isEmpty) return null;
    final trimmed = s.trim();
    if (trimmed.length >= 10) {
      final sub = trimmed.substring(0, 10);
      final parts = sub.split(RegExp(r'[-/T]'));
      if (parts.length >= 3) {
        int? y, m, d;
        if (parts[0].length == 4) {
          y = int.tryParse(parts[0]);
          m = int.tryParse(parts[1]);
          d = int.tryParse(parts[2]);
        } else if (parts[2].length == 4) {
          d = int.tryParse(parts[0]);
          m = int.tryParse(parts[1]);
          y = int.tryParse(parts[2]);
        }
        if (y != null && m != null && d != null) {
          return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        }
      }
    }
    return trimmed;
  }

  String _formatFechaYyyyMmDd(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  /// Rayita para días pasados sin registro
  Widget _buildNoLlenoIcon() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 36.w,
      height: 36.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Container(width: 20.w, height: 2.h, color: colorScheme.outlineVariant),
    );
  }

  /// Bolita para días pendientes (futuros)
  Widget _buildPendienteIcon() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: const Color(0xFF0277BD), width: 2),
      ),
      child: Center(
        child: Container(
          width: 8.w,
          height: 8.h,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0277BD),
          ),
        ),
      ),
    );
  }

  num? _parsePromedio(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  Widget _buildDayLabel(String day) {
    return SizedBox(
      width: 36.w,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Calcula el estado emocional basado en el promedio (4 niveles)
  String _calcularEstadoDelPromedio(num promedio) {
    if (promedio >= 3.3) {
      return EmotionCalculator.EXCELENTE; // verde
    } else if (promedio >= 2.2) {
      return EmotionCalculator.NORMAL; // azul
    } else if (promedio >= 1.0) {
      return EmotionCalculator.ALERTA_AMARILLO; // amarillo
    } else {
      return EmotionCalculator.CRITICO; // rojo
    }
  }

  /// Construye un círculo de color según el estado emocional con IMAGEN adentro
  Widget _buildEstadoCircle(String estado, num promedio) {
    // Imágenes según el estado
    String imagenAsset;
    Color colorFondo;

    switch (estado) {
      case 'excelente':
        colorFondo = const Color(0xFF08D557); // Verde
        imagenAsset = 'assets/images/green_face.png';
        break;
      case 'normal':
        colorFondo = const Color(0xFF2196F3); // Azul
        imagenAsset = 'assets/images/rest.png';
        break;
      case 'alerta-amarillo':
        colorFondo = const Color(0xFFFF9800); // Amarillo/Naranja
        imagenAsset = 'assets/images/yellowrest.jpg';
        break;
      case 'critico':
        colorFondo = const Color(0xFFE91E63); // Rojo/Rosa
        imagenAsset = 'assets/images/pink_face.jpg';
        break;
      default:
        colorFondo = Colors.grey[300]!;
        imagenAsset = 'assets/images/normalrest.jpg';
    }

    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorFondo, colorFondo.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorFondo.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          imagenAsset,
          width: 50.w,
          height: 50.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback color si la imagen no existe
            return Container(
              color: colorFondo,
              child: Center(child: Text('😊', style: TextStyle(fontSize: 20.sp))),
            );
          },
        ),
      ),
    );
  }
}
