import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:rest/features/emotion/screens/emotionregister_screen.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';

import '../models/ova_models.dart';
import '../services/ova_pendientes.dart';
import '../services/ova_service.dart';
import '../widgets/ova_feedback_sheet.dart';
import '../widgets/ova_resource_view.dart';
import '../widgets/ova_ui.dart';
import 'ova_post_test_result_screen.dart';

class OvaDetailScreen extends StatefulWidget {
  const OvaDetailScreen({super.key, required this.asignacion});

  final OvaAsignacion asignacion;

  @override
  State<OvaDetailScreen> createState() => _OvaDetailScreenState();
}

class _OvaDetailScreenState extends State<OvaDetailScreen> {
  final _service = OvaService();
  late OvaAsignacion _asignacion = widget.asignacion;
  bool _busy = false;

  /// El recurso se muestra al comenzar; una actividad ya iniciada o completada
  /// lo muestra directamente.
  bool get _mostrarRecurso => _asignacion.estado != OvaEstado.pending;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on OvaException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'No pudimos completar la acción. Revisa tu conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reload() async {
    final updated = await _service.getAsignacion(_asignacion.id);
    if (mounted) setState(() => _asignacion = updated);
  }

  Future<void> _comenzar() => _run(() async {
    await _service.iniciar(_asignacion.id);
    await _reload();
    await OvaPendientes.refresh(service: _service);
  });

  Future<void> _terminar() => _run(() async {
    final feedback = await showOvaFeedbackSheet(context);
    if (feedback == null || !mounted) return;

    final resultado = await _service.completar(
      _asignacion.id,
      liked: feedback.liked,
      rating: feedback.rating,
    );
    await _reload();
    await OvaPendientes.refresh(service: _service);
    if (!mounted || !resultado.requierePostTest) return;

    final medirAhora = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cómo te sientes ahora?'),
        content: const Text(
          'Responder unas preguntas nos ayuda a saber si la actividad te sirvió.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Más tarde'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ahora'),
          ),
        ],
      ),
    );
    if (medirAhora == true && mounted) await _irAlPostTest();
  });

  Future<void> _irAlPostTest() async {
    final respuesta = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EmotionRegisterScreen(ovaAsignacionId: _asignacion.id),
      ),
    );
    if (respuesta == null || !mounted) return;

    final enlazado = respuesta['post_test_enlazado'] == true;
    // El delta se calcula en el backend: se vuelve a leer la asignación.
    OvaAsignacion? actualizada;
    try {
      actualizada = await _service.getAsignacion(_asignacion.id);
    } catch (_) {
      actualizada = null;
    }
    // El post-test puede asignar actividades nuevas.
    await OvaPendientes.refresh(service: _service);
    if (!mounted) return;

    if (actualizada != null) setState(() => _asignacion = actualizada!);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OvaPostTestResultScreen(
          enlazado: enlazado,
          mejoro: actualizada?.mejoro ?? false,
        ),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _omitir() async {
    final tipo = await showDialog<OvaOmision>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿Quieres dejar esta actividad?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, OvaOmision.skipped),
            child: const Text('Ahora no, quizá más adelante'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, OvaOmision.dismissed),
            child: const Text('No me interesa'),
          ),
        ],
      ),
    );
    if (tipo == null || !mounted) return;

    await _run(() async {
      await _service.omitir(_asignacion.id, tipo);
      await OvaPendientes.refresh(service: _service);
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ova = _asignacion.ova;
    final color = ovaTipoColor(context, ova.tipo);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            CarePageHeader(title: ova.titulo),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 40.h),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ovaTipoIcon(ova.tipo),
                          color: color,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        '${ovaTipoLabel(ova.tipo)} · ${ovaDuracion(ova)}',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (ova.descripcion != null) ...[
                    SizedBox(height: 14.h),
                    Text(
                      ova.descripcion!,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15.sp,
                        height: 1.4,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Text(
                    ovaMotivo(_asignacion),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (_mostrarRecurso)
                    OvaResourceView(recurso: ova.recurso)
                  else
                    _StartCard(onStart: _busy ? null : _comenzar),
                  SizedBox(height: 22.h),
                  ..._actions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final appColors = context.appColors;
    final colors = Theme.of(context).colorScheme;
    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: appColors.accentBlue,
      foregroundColor: appColors.overlayOnGradient,
      padding: EdgeInsets.symmetric(vertical: 15.h),
      textStyle: const TextStyle(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );

    if (_asignacion.necesitaPostTest) {
      return [
        Container(
          padding: EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            color: appColors.warmBadgeFg.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: appColors.warmBadgeFg.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            'Cuéntanos cómo te sientes después de la actividad. Son unas pocas preguntas.',
            style: TextStyle(
              fontFamily: 'Fredoka',
              height: 1.35,
              color: colors.onSurface,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        FilledButton.icon(
          onPressed: _busy ? null : () => _run(_irAlPostTest),
          icon: const Icon(Icons.favorite_outline_rounded),
          label: const Text('Medir cómo me siento'),
          style: primaryStyle,
        ),
      ];
    }

    if (!_asignacion.porHacer) return const [];

    return [
      if (_mostrarRecurso)
        FilledButton.icon(
          onPressed: _busy ? null : _terminar,
          icon: _busy
              ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Terminé'),
          style: primaryStyle,
        ),
      SizedBox(height: 6.h),
      TextButton(
        onPressed: _busy ? null : _omitir,
        child: Text(
          'Ahora no',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    ];
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.spa_outlined, size: 40.sp, color: appColors.accentTeal),
          SizedBox(height: 10.h),
          Text(
            'Busca un lugar tranquilo y toma unos minutos para ti.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14.sp,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16.h),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Comenzar'),
            style: FilledButton.styleFrom(
              backgroundColor: appColors.accentBlue,
              foregroundColor: appColors.overlayOnGradient,
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 13.h),
              textStyle: const TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
