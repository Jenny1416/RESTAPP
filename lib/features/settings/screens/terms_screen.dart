import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../home/screens/gradient_text.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/widgets/primary_gradient_button.dart';

class TermsScreen extends StatelessWidget {
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
            'Términos',
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
                        Icons.description,
                        color: appColors.overlayOnGradient,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Text(
                        'Términos y condiciones',
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

              // Contenido de términos
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
                    _buildTermSection(
                      context,
                      '1. Objeto del servicio',
                      'La aplicación tiene como finalidad brindar herramientas de apoyo emocional, seguimiento del bienestar mental, orientación general y recursos informativos mediante inteligencia artificial.',
                    ),

                    _buildTermSection(
                      context,
                      '2. Naturaleza del servicio',
                      'La aplicación no presta servicios médicos, psicológicos clínicos ni psiquiátricos. La información proporcionada no constituye diagnóstico, tratamiento ni reemplaza la atención profesional especializada.',
                    ),

                    _buildTermSection(
                      context,
                      '3. Registro y acceso',
                      'Para utilizar determinadas funciones, el usuario podrá crear una cuenta proporcionando información veraz, actualizada y completa. El usuario es responsable de la seguridad de sus credenciales de acceso.',
                    ),

                    _buildTermSection(
                      context,
                      '4. Uso adecuado de la plataforma',
                      'El usuario se compromete a utilizar la aplicación de manera lícita, ética y responsable, absteniéndose de realizar actividades que afecten el funcionamiento del sistema o perjudiquen a terceros.',
                    ),

                    _buildTermSection(
                      context,
                      '5. Privacidad y tratamiento de datos',
                      'Los datos personales suministrados serán tratados conforme a la Política de Privacidad de la aplicación y la normativa vigente de protección de datos personales.',
                    ),

                    _buildTermSection(
                      context,
                      '6. Inteligencia artificial',
                      'Las respuestas generadas por inteligencia artificial son automáticas, orientativas y pueden presentar limitaciones o errores. Se recomienda validar información sensible con profesionales competentes.',
                    ),

                    _buildTermSection(
                      context,
                      '7. Situaciones de emergencia',
                      'La aplicación no sustituye servicios de emergencia. En casos de crisis emocional, riesgo suicida o peligro inmediato, el usuario deberá acudir a líneas de atención, servicios médicos o autoridades competentes.',
                    ),

                    _buildTermSection(
                      context,
                      '8. Propiedad intelectual',
                      'El diseño, contenido, software, logotipos y funcionalidades de la aplicación son propiedad de sus desarrolladores o titulares autorizados y están protegidos por la legislación aplicable.',
                    ),

                    _buildTermSection(
                      context,
                      '9. Suspensión de uso',
                      'La administración podrá suspender o restringir el acceso a usuarios que incumplan estos términos o hagan uso indebido de la plataforma.',
                    ),

                    _buildTermSection(
                      context,
                      '10. Modificaciones',
                      'Los presentes términos podrán ser actualizados en cualquier momento. Las modificaciones serán notificadas dentro de la aplicación.',
                      isLast: true,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              GestureDetector(
                onTap: () => _showAcceptanceDialog(context),
                child: const PrimaryGradientButton(
                  label: 'He leído y acepto',
                  height: 55,
                  fontSize: 16,
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermSection(BuildContext context, String title, String content, {bool isLast = false}) {
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

  void _showAcceptanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            '¡Términos aceptados!',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Has aceptado los términos y condiciones de uso de la aplicación.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a configuración
              },
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: context.appColors.brandSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}