import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de confirmación cuando el registro emocional se guarda correctamente.
/// Aparece después de completar el test y antes del semáforo emocional.
class EmotionSavedScreen extends StatefulWidget {
  final Map<String, dynamic>
  resultado; // Datos del test para pasar a traffic light

  const EmotionSavedScreen({super.key, required this.resultado});

  @override
  State<EmotionSavedScreen> createState() => _EmotionSavedScreenState();
}

class _EmotionSavedScreenState extends State<EmotionSavedScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _slideController;
  late Animation<double> _checkAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animación del checkmark
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    // Animación de slide para el texto
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Navegar a WhatsApp después de 10 segundos
    Future.delayed(const Duration(seconds: 10), () async {
      if (mounted) {
        // Número de WhatsApp del psicólogo - CONFIGURA AQUÍ TU NÚMERO
        const String psychologistPhone =
            '+573015460169'; // Sin espacios para WhatsApp
        const String message =
            'Hola, he enviado una solicitud de ayuda desde REST.';
        final normalizedPhone = _normalizePhone(psychologistPhone);

        // Crear URLs de WhatsApp
        final Uri nativeUri = Uri(
          scheme: 'whatsapp',
          path: 'send',
          queryParameters: {'phone': normalizedPhone, 'text': message},
        );
        final Uri webUri = Uri.parse(
          'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
        );

        try {
          if (await canLaunchUrl(nativeUri)) {
            await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
          } else if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
            // Cerrar la pantalla después de abrir WhatsApp
            if (mounted) {
              Navigator.pop(context);
            }
          } else {
            // Si no se puede abrir WhatsApp, ir al traffic light como fallback
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.trafficLight,
              arguments: widget.resultado,
            );
          }
        } catch (e) {
          // En caso de error, ir al traffic light
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.trafficLight,
            arguments: widget.resultado,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _normalizePhone(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!digits.startsWith('+')) {
      digits = '+$digits';
    }
    if (digits.startsWith('+57')) {
      return digits;
    }
    final justDigits = digits.replaceAll('+', '');
    if (justDigits.length == 10) {
      return '+57$justDigits';
    }
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
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
                  color: Colors.black.withValues(alpha: 0.15),
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
                  // Checkmark animado
                  ScaleTransition(
                    scale: _checkAnimation,
                    child: Container(
                      width: 120.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [appColors.successFg, appColors.progressFillCool],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: appColors.successFg.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 70,
                          color: appColors.overlayOnGradient,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Texto principal con animación de slide
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _slideController,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                appColors.successFg,
                                appColors.progressFillCool,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              '¡REGISTRO\nEMOCIONAL\nGUARDADO!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36.sp,
                                fontWeight: FontWeight.w900,
                                color: appColors.overlayOnGradient,
                                letterSpacing: 1.2,
                                height: 1.2,
                              ),
                            ),
                          ),

                          SizedBox(height: 16.h),

                          Text(
                            'Tu estado de ánimo ha sido registrado con éxito',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Indicador de carga animado
                  SizedBox(
                    width: 60.w,
                    height: 60.h,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.outlineVariant,
                      ),
                      strokeWidth: 3,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  Text(
                    'Preparando tu resultado...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
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
