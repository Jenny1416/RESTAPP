import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../home/screens/gradient_text.dart';
import 'package:rest/core/theme/app_colors.dart';

class PrivacityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leadingWidth: 70,
        leading: Center(
          child: Container(
            margin: const EdgeInsets.only(left: 20),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: appColors.brandBorder,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: appColors.overlayOnGradient,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
        title: Container(
          margin: const EdgeInsets.only(left: 10),
          child: GradientText(
            'Privacidad',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 30.sp,
            ),
            gradient: LinearGradient(
              colors: [
                appColors.accentTeal,
                appColors.accentBlue,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [appColors.accentTeal, appColors.accentBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.privacy_tip,
                        color: appColors.overlayOnGradient,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Text(
                        'Aviso de privacidad',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              // Contenido de privacidad
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacySection(
                      context,
                      '1. Responsable del tratamiento de datos',
                      'Los datos personales recopilados a través de la aplicación serán administrados por los desarrolladores o entidad responsable del proyecto, quienes velarán por su adecuado tratamiento y seguridad.',
                    ),

                    _buildPrivacySection(
                      context,
                      '2. Datos que pueden recopilarse',
                      'La aplicación podrá solicitar o almacenar información como:\n\n'
                      'Nombre o alias de usuario.\n'
                      'Correo electrónico institucional o personal.\n'
                      'Edad o rango de edad.\n'
                      'Información académica básica (programa, semestre, universidad).\n'
                      'Respuestas en evaluaciones emocionales o cuestionarios de bienestar.\n'
                      'Historial de uso de funciones dentro de la aplicación.\n'
                      'Datos técnicos del dispositivo necesarios para el funcionamiento.',
                    ),

                    _buildPrivacySection(
                      context,
                      '3. Finalidad del tratamiento',
                      'La información recopilada será utilizada para:\n\n'
                      'Permitir el acceso y funcionamiento de la aplicación.\n'
                      'Personalizar recomendaciones y herramientas de apoyo emocional.\n'
                      'Realizar seguimiento del bienestar mental del usuario.\n'
                      'Mejorar la experiencia de uso y desempeño del sistema.\n'
                      'Generar estadísticas generales con fines académicos o de mejora continua.\n'
                      'Atender solicitudes, soporte o reportes realizados por el usuario.',
                    ),

                    _buildPrivacySection(
                      context,
                      '4. Confidencialidad y seguridad',
                      'Los datos personales recopilados a través de la aplicación serán administrados por los desarrolladores o entidad responsable del proyecto, quienes velarán por su adecuado tratamiento y seguridad.',
                    ),

                    _buildPrivacySection(
                      context,
                      '5. Compartición de información',
                      'Los datos personales no serán vendidos ni compartidos con terceros sin autorización del usuario, salvo obligación legal o cuando sea necesario para prestar servicios tecnológicos asociados al funcionamiento de la aplicación.',
                    ),

                    _buildPrivacySection(
                      context,
                      '6. Derechos del usuario',
                      'El usuario podrá solicitar en cualquier momento:\n\n'
                      'Conocer los datos almacenados.\n'
                      'Actualizar o corregir información.\n'
                      'Solicitar eliminación de la cuenta y datos asociados.\n'
                      'Revocar autorizaciones otorgadas, cuando aplique.',
                    ),

                    _buildPrivacySection(
                      context,
                      '7. Conservación de datos',
                      'La información será conservada durante el tiempo necesario para cumplir las finalidades descritas o mientras el usuario mantenga activa su cuenta.',
                    ),

                    _buildPrivacySection(
                      context,
                      '8. Uso de inteligencia artificial',
                      'Algunas funciones utilizan inteligencia artificial para generar recomendaciones o respuestas automatizadas. Estas herramientas no reemplazan atención profesional en salud mental.',
                    ),

                    _buildPrivacySection(
                      context,
                      '9. Cambios al aviso de privacidad',
                      'Este aviso podrá ser actualizado en cualquier momento. Los cambios serán informados dentro de la aplicación.',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, String title, String content, {bool isLast = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (!isLast) SizedBox(height: 20.h),
      ],
    );
  }
}