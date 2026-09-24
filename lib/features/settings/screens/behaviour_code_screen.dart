import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../home/screens/gradient_text.dart';
import 'package:rest/core/theme/app_colors.dart';

class BehaviourCodeScreen extends StatelessWidget {
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
                child: Icon(Icons.arrow_back, color: appColors.overlayOnGradient, size: 25),
              ),
            ),
          ),
        ),
        title: Container(
          margin: const EdgeInsets.only(left: 10),
          child: GradientText(
            'Código',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30.sp),
            gradient: LinearGradient(
              colors: [appColors.accentTeal, appColors.accentBlue],
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
                      child: Icon(Icons.gavel, color: appColors.overlayOnGradient, size: 28),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Text(
                        'Código de conducta',
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

              // Contenido del código de conducta
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
                    _buildCodeSection(
                      context,
                      'Artículo 1. Respeto e integridad',
                      'Todos los usuarios deberán interactuar dentro de la plataforma con respeto, cortesía y responsabilidad, evitando cualquier conducta ofensiva, discriminatoria, intimidatoria o que vulnere la dignidad de otras personas.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 2. Uso adecuado de la plataforma',
                      'El aplicativo deberá ser utilizado exclusivamente con fines de orientación, acompañamiento emocional, prevención y promoción del bienestar psicológico de la comunidad estudiantil.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 3. Alcance de la inteligencia artificial',
                      'Las herramientas de inteligencia artificial incorporadas en la aplicación constituyen un mecanismo de apoyo complementario y en ningún caso reemplazan la valoración, diagnóstico o tratamiento brindado por profesionales de la salud mental.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 4. Privacidad y confidencialidad',
                      'Toda información suministrada por los usuarios será tratada bajo criterios de confidencialidad, seguridad y protección de datos personales, conforme a la normativa vigente aplicable.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 5. Veracidad de la información',
                      'Los usuarios deberán proporcionar información veraz y actualizada en los formularios, evaluaciones y demás instrumentos dispuestos por la aplicación, con el fin de obtener resultados adecuados y recomendaciones pertinentes.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 6. Conductas prohibidas',
                      'Se prohíbe expresamente el uso de la plataforma para:\n'
                      'a) Promover violencia, acoso o discriminación.\n'
                      'b) Difundir información falsa o malintencionada.\n'
                      'c) Incentivar autolesiones, suicidio o consumo de sustancias psicoactivas.\n'
                      'd) Vulnerar la seguridad informática del sistema.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 7. Atención en situaciones de riesgo',
                      'En caso de identificar señales asociadas a crisis emocional, riesgo suicida u otras situaciones de urgencia psicológica, la aplicación orientará al usuario hacia canales institucionales, líneas de emergencia o atención profesional especializada.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 8. Inclusión y equidad',
                      'El aplicativo garantizará igualdad de acceso y trato digno a todos los usuarios, sin discriminación por razones de género, edad, orientación sexual, etnia, condición socioeconómica, religión o discapacidad.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 9. Mejoramiento continuo',
                      'Se promoverá la retroalimentación constante por parte de los usuarios, con el propósito de fortalecer la calidad, pertinencia y funcionamiento ético del aplicativo.',
                    ),

                    _buildCodeSection(
                      context,
                      'Artículo 10. Compromiso institucional',
                      'El desarrollo y uso de la aplicación estarán orientados al fortalecimiento de la salud mental universitaria, la prevención de riesgos psicosociales y la generación de entornos académicos saludables.',
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

  Widget _buildCodeSection(
    BuildContext context,
    String title,
    String content, {
    bool isLast = false,
  }) {
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
