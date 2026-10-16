import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';
import '../utils/emotion_state_config.dart';

class AdviceScreen extends StatelessWidget {
  final String userName;
  final String adviceTitle;
  final String message;
  final double? promedioHoy;
  final String estado; // Nuevo parámetro de estado

  const AdviceScreen({
    Key? key,
    required this.userName,
    required this.adviceTitle,
    required this.message,
    this.promedioHoy,
    this.estado = 'normal',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final config = EmotionStateConfig.getConfig(estado, context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: config.colorPrincipal,
        foregroundColor: appColors.overlayOnGradient,
        elevation: 0,
        title: Text(
          'Cuidado Personal',
          style: TextStyle(
            color: appColors.overlayOnGradient,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de encabezado con cara y saludo
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: config.colorPrincipal.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Cara del usuario con emoji
                    Container(
                      width: 90.w,
                      height: 90.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: config.colorPrincipal,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: config.colorPrincipal.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          config.imagenAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.sentiment_satisfied,
                            size: 50,
                            color: config.colorPrincipal,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Saludo y mensaje de bienvenida
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${UserSession.displayName}!',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: config.colorPrincipal,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Aquí encontrarás recomendaciones',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Título de sección
              Text(
                config.titulo,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: config.colorPrincipal,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: 12.h),

              // Mensaje contextual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: config.colorPrincipal.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.mensaje,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: config.colorTexto,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      config.mensaje2,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: config.colorTexto.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Sección de Recomendaciones
              Text(
                '💡 Recomendaciones para ti:',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),

              SizedBox(height: 16.h),

              // Lista de recomendaciones
              ...config.recomendaciones.map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: config.colorPrincipal.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      rec,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),

              SizedBox(height: 32.h),

              // Sección de recursos según el estado
              if (estado == 'preocupante' || estado == 'critico') ...[
                Text(
                  '🆘 Recursos de Ayuda:',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.dangerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: appColors.dangerFg.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResourceItem(
                        'PAS Colombia',
                        '123',
                        appColors.dangerFg,
                        context,
                      ),
                      SizedBox(height: 10.h),
                      _buildResourceItem(
                        'Línea de Emergencia Mental',
                        '+57 1 2288019',
                        appColors.goldEnd,
                        context,
                      ),
                      SizedBox(height: 10.h),
                      _buildResourceItem(
                        'Chat con Psicólogo (24h)',
                        'Disponible en la app',
                        appColors.brandBorder,
                        context,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
              ],

              // Botón de acción
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.colorPrincipal,
                    foregroundColor: appColors.overlayOnGradient,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    shadowColor: config.colorPrincipal.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    // Después de leer consejos, ir al registro guardado
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.check,
                      arguments: {'promedioHoy': promedioHoy},
                    );
                  },
                  child: Text(
                    'Ver Registro Guardado →',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceItem(String title, String contact, Color color, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: color, size: 20),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  contact,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
