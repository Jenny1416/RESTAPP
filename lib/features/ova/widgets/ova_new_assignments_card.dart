import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';

import '../models/ova_models.dart';
import '../screens/ova_list_screen.dart';
import '../services/ova_pendientes.dart';
import '../services/ova_service.dart';
import 'ova_ui.dart';

/// En el resultado de una evaluación muestra las actividades que el estudiante
/// tiene por hacer. Consulta el listado (GET) en vez de usar `ovas_asignados`,
/// porque ese arreglo tiene otra forma. Si falla, no muestra nada.
class OvaNewAssignmentsCard extends StatefulWidget {
  const OvaNewAssignmentsCard({super.key});

  @override
  State<OvaNewAssignmentsCard> createState() => _OvaNewAssignmentsCardState();
}

class _OvaNewAssignmentsCardState extends State<OvaNewAssignmentsCard> {
  List<OvaAsignacion> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await OvaService().getAsignaciones();
      OvaPendientes.actualizar(items);
      if (!mounted) return;
      setState(() => _items = items.where((item) => item.porHacer).toList());
    } catch (_) {
      // Es un extra del resultado: nunca debe estorbar la pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final visibles = _items.take(3).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: appColors.accentTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: appColors.accentTeal.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa_outlined, color: appColors.accentTeal),
                SizedBox(width: 8.w),
                Text(
                  'Actividades para ti',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w800,
                    fontSize: 16.sp,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            for (final item in visibles)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  children: [
                    Icon(
                      ovaTipoIcon(item.ova.tipo),
                      size: 18.sp,
                      color: colors.onSurfaceVariant,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '${item.ova.titulo} · ${ovaDuracion(item.ova)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 13.sp,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OvaListScreen()),
                  );
                  if (mounted) await _load();
                },
                child: const Text(
                  'Ver mis actividades',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
