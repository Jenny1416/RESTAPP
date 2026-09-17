import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rest/core/services/progress_service.dart';
import 'package:rest/features/progress/screens/activity_practice_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final ProgressService _progressService = ProgressService();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  DailyActivitiesSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _progressService.fetchActividadesDiarias();
      if (!mounted) return;
      setState(() {
        _summary = result;
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

  Future<void> _complete(DailyActivity activity) async {
    if (_sending) return;
    final result = await Navigator.of(context).push<ActivityPracticeResult>(
      MaterialPageRoute(
        builder: (_) => ActivityPracticeScreen(activity: activity),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _sending = true);
    try {
      await _progressService.completarActividadDiaria(
        opcionId: activity.id,
        observaciones: result.observations,
      );
      await _loadActivities();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Actividad completada: ${activity.nombre}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo completar: $e')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _summary?.pendientes ?? const <DailyActivity>[];
    final hechas = _summary?.hechas ?? const <DailyActivity>[];
    final formato = DateFormat('dd/MM/yyyy');
    final hoy = formato.format(DateTime.now());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0BBDAC), Color(0xFF6110E8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Color(0xFF0BBDAC), Color(0xFF6110E8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Text(
                          'Mis Actividades',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 30.w), // Para balancear el espacio de la X
                ],
              ),
            ),

            Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
              thickness: 2,
              height: 0.h,
              indent: 16,
              endIndent: 16,
            ),

            SizedBox(height: 20.h),

            // Texto motivacional
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Fredoka',
                  ),
                  children: [
                    TextSpan(text: '⭐ '),
                    TextSpan(
                      text:
                          'Realiza las actividades y reclama tus premios personalizados!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Grid de actividades
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No se pudo cargar actividades',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                          SizedBox(height: 8.h),
                          Text(_error!, textAlign: TextAlign.center),
                          SizedBox(height: 10.h),
                          ElevatedButton(
                            onPressed: _loadActivities,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(
                          2,
                        ), // Grosor del borde con gradiente
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0BBDAC), Color(0xFF6110E8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              if (pendientes.isEmpty && hechas.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No hay actividades disponibles hoy.',
                                  ),
                                ),
                              ...pendientes
                                  .map(
                                    (a) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _buildActivityCard(
                                        a.nombre,
                                        'assets/images/Play.png',
                                        hoy,
                                        completed: false,
                                        onAction: () => _complete(a),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              ...hechas
                                  .map(
                                    (a) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _buildActivityCard(
                                        a.nombre,
                                        'assets/images/medalla.png',
                                        hoy,
                                        completed: true,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String imagePath,
    String date, {
    bool completed = false,
    VoidCallback? onAction,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen de la actividad
              Container(
                width: 80.w,
                height: 80.h,
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
              SizedBox(height: 12.h),

              // Título de la actividad
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: completed || onAction == null || _sending
                      ? null
                      : onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: completed
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF0BBDAC),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: Text(completed ? 'Completada' : 'Realizar'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        // Fecha de vencimiento fuera de la tarjeta
        Text(
          'Vence el:',
          style: TextStyle(fontSize: 11.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Text(
          date,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
