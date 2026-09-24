import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rest/core/services/diary_service.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'mi_diario_screen.dart';

class MisCapitulosScreen extends StatefulWidget {
  const MisCapitulosScreen({super.key});

  @override
  State<MisCapitulosScreen> createState() => _MisCapitulosScreenState();
}

class _MisCapitulosScreenState extends State<MisCapitulosScreen> {
  final DiaryService _diaryService = DiaryService();

  bool _loading = true;
  String? _error;
  List<DiaryEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _diaryService.fetchEntries();
      if (!mounted) return;
      setState(() {
        _entries = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const MiDiarioScreen()),
          );
          if (changed == true) _loadEntries();
        },
        backgroundColor: appColors.successFg,
        foregroundColor: appColors.overlayOnGradient,
        icon: const Icon(Icons.add),
        label: const Text('Crear diario nuevo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
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

                      ShaderMask(
                        shaderCallback: (bounds) =>
                            gradient.createShader(bounds),
                        child: Text(
                          'Mis Capítulos',
                          style: GoogleFonts.fredoka(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: appColors.overlayOnGradient,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // divisor
                  SizedBox(height: 20.h),
                  Divider(
                    color: colorScheme.outlineVariant,
                    thickness: 3,
                    height: 0.h,
                    indent: 23,
                    endIndent: 23,
                  ),
                ],
              ),
            ),

            // 🔹 LISTA DE CAPÍTULOS
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No se pudieron cargar tus capitulos',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: appColors.neutralMutedText,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 13.sp,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _loadEntries,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 80,
                            color: colorScheme.outlineVariant,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No hay capítulos aún',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'Fredoka',
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Comienza escribiendo en tu diario',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'Fredoka',
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEntries,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final capitulo = _entries[index];
                          return _buildCapituloCard(
                            context,
                            capitulo,
                            gradient,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapituloCard(
    BuildContext context,
    DiaryEntry entry,
    RadialGradient gradient,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MiDiarioScreen(entry: entry)),
        ).then((changed) { if (changed == true) _loadEntries(); });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(2), // gradiente
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title
              Text(
              entry.titulo,
                style: GoogleFonts.fredoka(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),

              // descrip
              Text(
              entry.contenido,
                style: GoogleFonts.fredoka(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12.h),

              // date
              Text(
              DateFormat('dd/MM/yyyy').format(entry.fecha),
                style: GoogleFonts.fredoka(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
