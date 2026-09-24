import 'package:flutter/material.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';
import '../../home/screens/home_screen.dart';
import 'help_screen.dart';

class CancelHelpScreen extends StatelessWidget {
  const CancelHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener ancho y alto de la pantalla
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: width * 0.85,
              margin: EdgeInsets.symmetric(horizontal: width * 0.075),
              padding: EdgeInsets.all(width * 0.06),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                border: Border.all(color: appColors.brandSoft, width: 2.5),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Imagen del muñequito mejorada
                  Container(
                    margin: EdgeInsets.only(bottom: height * 0.02),
                    child: Image.asset(
                      "assets/images/sadbluerest.png",
                      width: width * 0.5,
                      height: height * 0.35,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: width * 0.5,
                          height: height * 0.35,
                          decoration: BoxDecoration(
                            color: appColors.brandSoft.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.psychology_outlined,
                              size: 60,
                              color: appColors.brandSoft,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: height * 0.01),
                  // Título principal mejorado
                  Text(
                    "¿Estás Segura?",
                    style: TextStyle(
                      fontSize: width * 0.075,
                      fontWeight: FontWeight.w800,
                      color: appColors.warmBadgeFg,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: height * 0.015),
                  // Nombre del usuario dinámicamente
                  Text(
                    "¡Vamos ${UserSession.displayName}!",
                    style: TextStyle(
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.w800,
                      color: appColors.brandBorder,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height * 0.015),
                  // Mensaje motivacional
                  Text(
                    "¡No está mal buscar ayuda!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width * 0.065,
                      fontWeight: FontWeight.w700,
                      color: appColors.dangerFg,
                      letterSpacing: 0.2,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: height * 0.025),
                  // Texto explicativo
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: height * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.brandSoft.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: appColors.brandSoft.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      "Contamos con profesionales dispuestos a ayudarte. Tu bienestar es nuestra prioridad.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  // Botones mejorados
                  Column(
                    children: [
                      // Botón 1: Volver a enviar
                      SizedBox(
                        width: double.infinity,
                        height: height * 0.065,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.successFg,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadowColor: appColors.successFg.withValues(alpha: 0.4),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HelpScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.arrow_forward,
                            color: appColors.overlayOnGradient,
                            size: 18,
                          ),
                          label: Text(
                            "Sí, Enviar Solicitud",
                            style: TextStyle(
                              color: appColors.overlayOnGradient,
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.015),
                      // Botón 2: No gracias
                      SizedBox(
                        width: double.infinity,
                        height: height * 0.065,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.dangerFg,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadowColor: appColors.dangerFg.withValues(alpha: 0.4),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.close,
                            color: appColors.overlayOnGradient,
                            size: 18,
                          ),
                          label: Text(
                            "No, Volver al Inicio",
                            style: TextStyle(
                              color: appColors.overlayOnGradient,
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
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
