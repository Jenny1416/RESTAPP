import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';

/// Cierre del post-test. Habla en términos cualitativos: no muestra puntajes.
class OvaPostTestResultScreen extends StatelessWidget {
  const OvaPostTestResultScreen({
    super.key,
    required this.enlazado,
    required this.mejoro,
  });

  /// El backend pudo asociar la medición a la actividad.
  final bool enlazado;

  /// Después de la actividad el estudiante se siente mejor que antes.
  final bool mejoro;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final bool mejora = enlazado && mejoro;

    final title = mejora ? '¡Qué bueno!' : 'Gracias por contarnos';
    final message = mejora
        ? 'Después de la actividad te sientes mejor. Sigue cuidándote así.'
        : enlazado
        ? 'Cada paso cuenta. Si lo necesitas, tu psicólogo puede acompañarte.'
        : 'Guardamos tus respuestas.';

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110.w,
                height: 110.w,
                decoration: BoxDecoration(
                  color: (mejora ? appColors.successFg : appColors.accentBlue)
                      .withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  mejora
                      ? Icons.sentiment_very_satisfied_rounded
                      : Icons.favorite_rounded,
                  size: 56.sp,
                  color: mejora ? appColors.successFg : appColors.accentBlue,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w800,
                  fontSize: 26.sp,
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 15.sp,
                  height: 1.4,
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: appColors.accentBlue,
                    foregroundColor: appColors.overlayOnGradient,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    textStyle: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
