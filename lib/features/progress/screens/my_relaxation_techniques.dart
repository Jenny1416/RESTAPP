import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';

class MisTecnicasScreen extends StatelessWidget {
  const MisTecnicasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tecnicas = [
      {'nombre': 'Yoga', 'icono': 'assets/images/yoga.png'},
      {'nombre': 'Chistes', 'icono': 'assets/images/chistes.png'},
      {'nombre': 'Juegos', 'icono': 'assets/images/juegos.png'},
      {'nombre': 'Escuchar Música', 'icono': 'assets/images/musica.png'},
      {'nombre': 'Actividad Física', 'icono': 'assets/images/gym.png'},
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final gradient = LinearGradient(
      colors: [appColors.accentTeal, appColors.accentBlue],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón "X" con gradiente
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: gradient,
                    ),
                    child: Icon(
                      Icons.close,
                      color: appColors.overlayOnGradient,
                      size: 24,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // Título con texto degradado
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Text(
                    'Mis Técnicas de\nRelajación',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 34.sp,
                      fontWeight: FontWeight.bold,
                      color: appColors.overlayOnGradient,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '⭐ Lo importante es mantener la calma y hacer algo que disfrutes',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Cuadro principal con borde degradado
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: gradient,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                      children: List.generate(tecnicas.length, (index) {
                        final tecnica = tecnicas[index];
                        return _buildTecnicaCard(
                          context,
                          tecnica['nombre']!,
                          tecnica['icono']!,
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta individual sin borde y con color azul #CCF0FF
  Widget _buildTecnicaCard(
    BuildContext context,
    String nombre,
    String iconPath,
  ) {
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: appColors.infoBadgeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 6,
              child: Image.asset(
                iconPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  color: colorScheme.onSurfaceVariant,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              flex: 3,
              child: Text(
                nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
