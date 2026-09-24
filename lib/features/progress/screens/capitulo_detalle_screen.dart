import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/theme/app_colors.dart';

class CapituloDetalleScreen extends StatefulWidget {
  final String? titulo;
  final String? descripcion;
  final String? fecha;

  const CapituloDetalleScreen({
    super.key,
    this.titulo,
    this.descripcion,
    this.fecha,
  });

  @override
  State<CapituloDetalleScreen> createState() => _CapituloDetalleScreenState();
}

class _CapituloDetalleScreenState extends State<CapituloDetalleScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.titulo ?? '');
    _descripcionController =
        TextEditingController(text: widget.descripcion ?? '');
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [appColors.accentTeal, appColors.accentBlue],
    );
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER
              Row(
                children: [
                  // Botón atrás con gradiente
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: appColors.overlayOnGradient,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // Texto "Capítulo" con gradiente
                  ShaderMask(
                    shaderCallback: (bounds) => gradient.createShader(bounds),
                    child: Text(
                      'Capítulo',
                      style: GoogleFonts.fredoka(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: appColors.overlayOnGradient,
                      ),
                    ),
                  ),
                ],
              ),

              // 🔸 Divider como en otras pantallas
              SizedBox(height: 20.h),
              Divider(
                color: colorScheme.outlineVariant,
                thickness: 3,
                height: 0.h,
                indent: 23,
                endIndent: 23,
              ),
              SizedBox(height: 20.h),

              // 🔹 FORMULARIO
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(2), // borde gradiente
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        // Campo Título
                        TextField(
                          controller: _tituloController,
                          style: GoogleFonts.fredoka(
                            fontSize: 16.sp,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Título......',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'Fredoka',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Divider(
                          color: colorScheme.outlineVariant,
                          thickness: 1,
                        ),
                        SizedBox(height: 8.h),

                        // Campo Descripción
                        Expanded(
                          child: TextField(
                            controller: _descripcionController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: GoogleFonts.fredoka(
                              fontSize: 14.sp,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Descripción......',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontFamily: 'Fredoka',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
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
}
