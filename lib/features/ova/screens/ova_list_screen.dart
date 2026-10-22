import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';

import '../models/ova_models.dart';
import '../services/ova_pendientes.dart';
import '../services/ova_service.dart';
import '../widgets/ova_ui.dart';
import 'ova_detail_screen.dart';

class OvaListScreen extends StatefulWidget {
  const OvaListScreen({super.key});

  @override
  State<OvaListScreen> createState() => _OvaListScreenState();
}

class _OvaListScreenState extends State<OvaListScreen> {
  final _service = OvaService();
  bool _loading = true;
  String? _error;
  List<OvaAsignacion> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent) _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getAsignaciones();
      OvaPendientes.actualizar(items);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on OvaException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar tus actividades. Revisa tu conexión.';
        _loading = false;
      });
    }
  }

  Future<void> _open(OvaAsignacion item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OvaDetailScreen(asignacion: item)),
    );
    if (mounted) await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CarePageHeader(
              title: 'Mis actividades',
              subtitle: 'Ejercicios recomendados para ti',
            ),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return CareEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos cargar tus actividades',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }

    final porHacer = _items.where((item) => item.porHacer).toList();
    final porMedir = _items.where((item) => item.necesitaPostTest).toList();
    if (porHacer.isEmpty && porMedir.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: 60.h),
            const CareEmptyState(
              icon: Icons.spa_outlined,
              title: 'Aún no tienes actividades',
              message:
                  'Cuando tu evaluación lo requiera, te recomendaremos ejercicios aquí.',
            ),
          ],
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 110.h),
        children: [
          if (porHacer.isNotEmpty) ...[
            _SectionTitle('Por hacer', colors),
            for (final item in porHacer) ...[
              _OvaCard(asignacion: item, onTap: () => _open(item)),
              SizedBox(height: 11.h),
            ],
          ],
          if (porMedir.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _SectionTitle('Mide cómo te sientes', colors),
            for (final item in porMedir) ...[
              _OvaCard(asignacion: item, onTap: () => _open(item)),
              SizedBox(height: 11.h),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.colors);

  final String text;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w800,
          fontSize: 18.sp,
          color: colors.onSurface,
        ),
      ),
    );
  }
}

class _OvaCard extends StatelessWidget {
  const _OvaCard({required this.asignacion, required this.onTap});

  final OvaAsignacion asignacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final ova = asignacion.ova;
    final color = ovaTipoColor(context, ova.tipo);
    final porMedir = asignacion.necesitaPostTest;

    final String etiqueta;
    final Color etiquetaColor;
    if (porMedir) {
      etiqueta = 'Cuéntanos cómo te sientes';
      etiquetaColor = appColors.warmBadgeFg;
    } else if (asignacion.estado == OvaEstado.inProgress) {
      etiqueta = 'En curso';
      etiquetaColor = appColors.accentBlue;
    } else {
      etiqueta = 'Nueva';
      etiquetaColor = appColors.successFg;
    }

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(11.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ovaTipoIcon(ova.tipo), color: color, size: 25.sp),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ova.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${ovaTipoLabel(ova.tipo)} · ${ovaDuracion(ova)}',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12.sp,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: etiquetaColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        etiqueta,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                          color: etiquetaColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
