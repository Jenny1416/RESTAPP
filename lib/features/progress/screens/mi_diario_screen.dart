import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/diary_service.dart';

class MiDiarioScreen extends StatefulWidget {
  const MiDiarioScreen({super.key, this.entry});

  final DiaryEntry? entry;

  @override
  State<MiDiarioScreen> createState() => _MiDiarioScreenState();
}

class _MiDiarioScreenState extends State<MiDiarioScreen> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final DiaryService _diaryService = DiaryService();
  bool _saving = false;

  final _gradient = const RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [Color(0xFF5CCFC0), Color(0xFF2981C1)],
  );

  @override
  void initState() {
    super.initState();
    _tituloController.text = widget.entry?.titulo ?? '';
    _descripcionController.text = widget.entry?.contenido ?? '';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_saving) return;

    final titulo = _tituloController.text.trim();
    final contenido = _descripcionController.text.trim();

    if (titulo.isEmpty || contenido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa titulo y descripcion para guardar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final entry = widget.entry;
      if (entry == null) {
        await _diaryService.createEntry(titulo: titulo, contenido: contenido);
      } else {
        await _diaryService.updateEntry(
          id: entry.id,
          titulo: titulo,
          contenido: contenido,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.entry == null
              ? 'Entrada guardada correctamente'
              : 'Entrada actualizada correctamente'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Botón cerrar con gradiente
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        gradient: _gradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // Texto con gradiente “Mi Diario”
                  ShaderMask(
                    shaderCallback: (bounds) => _gradient.createShader(bounds),
                    child: Text(
                      'Mi Diario',
                      style: GoogleFonts.fredoka(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // se pinta con el ShaderMask
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                color: colorScheme.outlineVariant,
                thickness: 3,
                height: 0.h,
                indent: 23,
                endIndent: 23,
              ),
              SizedBox(height: 8.h),

              // Mensaje de advertencia
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFA726),
                      size: 20,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Recuerda que este espacio es solo tuyo. Nadie puede leer tus notas; es totalmente privado: tus pensamientos y tú.',
                        style: GoogleFonts.fredoka(
                          fontSize: 15.sp,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Formulario con borde de gradiente
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: _gradient,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Campo título
                        TextField(
                          controller: _tituloController,
                          style: GoogleFonts.fredoka(
                            fontSize: 16.sp,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Título...',
                            hintStyle: GoogleFonts.fredoka(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const Divider(color: Color(0xFFE0E0E0), thickness: 1),
                        SizedBox(height: 8.h),

                        // Campo descripción
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
                              hintText: 'Descripción...',
                              hintStyle: GoogleFonts.fredoka(
                                color: colorScheme.onSurfaceVariant,
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
              SizedBox(height: 20.h),

              // Botones
              Row(
                children: [
                  // Botón “Ver mis capítulos” con gradiente
                  Expanded(
                    child: Container(
                      height: 52.h,
                      decoration: BoxDecoration(
                        gradient: _gradient,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.misCapitulos);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Ver mis Capítulos',
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Botón “Guardar” (verde, sin cambios)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                          widget.entry == null ? 'Guardar' : 'Guardar cambios',
                              style: GoogleFonts.fredoka(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
    );
  }
}
