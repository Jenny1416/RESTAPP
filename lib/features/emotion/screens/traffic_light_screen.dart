import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/routes/app_routes.dart';
import '../../../core/services/user_session.dart';
import '../../evaluations/widgets/latest_dimensions_card.dart';
import '../utils/emotion_state_config.dart';

class TrafficLightScreen extends StatelessWidget {
  final String estado;
  final String mensaje;
  final String botonTexto;
  final double?
  promedioHoy; // Para pasar a CheckScreen y mostrar la carita del día
  const TrafficLightScreen({
    super.key,
    required this.estado,
    required this.mensaje,
    required this.botonTexto,
    this.promedioHoy,
  });

  @override
  Widget build(BuildContext context) {
    final config = EmotionStateConfig.getConfig(estado);
    final recomendaciones = config.getRandomRecommendations(count: 3);

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circulo decorativo de fondo
                  Container(
                    width: 280.w,
                    height: 220.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          config.colorPrincipal.withValues(alpha: 0.15),
                          config.colorPrincipal.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          config.imagenAsset,
                          width: 200.w,
                          height: 200.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.sentiment_satisfied,
                              size: 100,
                              color: config.colorPrincipal,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Título dinámico con color según estado
                  Text(
                    config.titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                      color: config.colorPrincipal,
                      letterSpacing: 0.8,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Contenedor del mensaje principal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: config.colorPrincipal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: config.colorPrincipal.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          config.mensaje,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: config.colorTexto,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          config.mensaje2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: config.colorTexto.withValues(alpha: 0.8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Recomendaciones quick tips
                  if (estado != 'excelente' && recomendaciones.isNotEmpty) ...[
                    Text(
                      'Sugerencias de bienestar:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: recomendaciones
                            .map(
                              (rec) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  rec,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  const LatestDimensionsCard(),
                  SizedBox(height: 24.h),

                  // Botón de acción
                  Container(
                    width: 220.w,
                    height: 55.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [config.colorPrincipal, config.colorSecundario],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: config.colorPrincipal.withValues(alpha: 0.4),
                          blurRadius: 12,
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
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        // TODAS las rutas van a CheckScreen (Registro Guardado)
                        if (estado == 'alerta-amarillo' ||
                            estado == 'critico') {
                          // Primero mostrar consejos, luego ir a registro guardado
                          Navigator.of(context).pushNamed(
                            AppRoutes.advice,
                            arguments: {
                              'estado': estado,
                              'userName': UserSession.displayName,
                            },
                          );
                        } else {
                          // Estados buenos van directo a registro guardado
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.check,
                            arguments: {'promedioHoy': promedioHoy},
                          );
                        }
                      },
                      child: Text(
                        config.botonTexto,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
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
}
