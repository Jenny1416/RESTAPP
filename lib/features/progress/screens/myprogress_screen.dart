import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/features/progress/screens/globalprogress_screen.dart';
import 'package:rest/core/services/personal_progress_service.dart';
import 'package:rest/core/theme/app_colors.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/services/user_session.dart';
import '../../../core/widgets/app_header_bar.dart';
import '../../../core/widgets/info_card.dart';

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  final PersonalProgressService _personalService = PersonalProgressService();

  bool _loading = true;
  bool _activatingStreak = false;
  String? _error;
  PersonalDashboardSummary? _data;

  @override
  void initState() {
    super.initState();
    _loadPersonalData();
  }

  Future<void> _loadPersonalData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _personalService.fetchPantallaPersonal();
      if (!mounted) return;
      setState(() {
        _data = result;
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

  Future<void> _activarRachaDiaria() async {
    if (_activatingStreak || _data?.estrellaHoyActivada == true ||
        _data?.puedeActivarEstrellaHoy != true) return;
    setState(() => _activatingStreak = true);

    try {
      final result = await _personalService.activarRachaDiaria();
      if (!mounted) return;

      if (!result.activada) {
        await _loadPersonalData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.mensaje)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.mensaje),
          backgroundColor: context.appColors.successFg,
        ),
      );

      await _loadPersonalData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo activar la estrella diaria: $e'),
          backgroundColor: context.appColors.dangerFg,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activatingStreak = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final diasTrabajados = _data?.diasTrabajadosEnMi ?? 0;

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPersonalData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context),
                Divider(
                  color: colorScheme.outlineVariant,
                  thickness: 3,
                  height: 0.h,
                  indent: 23,
                  endIndent: 23,
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    diasTrabajados == 1
                        ? 'He trabajado 1 día en mí'
                        : 'He trabajado $diasTrabajados días en mí',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Fredoka',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16.h),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: CircularProgressIndicator(),
                  )
                else if (_error != null)
                  _ErrorPanel(error: _error!, onRetry: _loadPersonalData)
                else ...[
                  _buildStreakCard(context),
                  SizedBox(height: 16.h),
                  _buildFrequentMoodCard(),
                  _buildFrequentEmotionsCard(),
                  _buildMoodEvolutionCard(),
                  _buildCreativeChallengeCard(),
                ],

                SizedBox(height: 90.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeaderBar(
      title: '¡Hola! ${UserSession.displayName}',
      onActionTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen()),
        );
      },
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final appColors = context.appColors;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GlobalProgressScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(color: appColors.brandBorder, width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.semanaActual
                  .map(
                    (day) => Expanded(
                      child: _DayItem(
                        day: day.dia,
                        active: day.estrellaActivada,
                        completed: day.registroEmocional,
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _MiniBadge(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Racha: ${data.rachaActual}',
                  bgColor: appColors.warmBadgeBg,
                  fgColor: appColors.warmBadgeFg,
                ),
                SizedBox(width: 8.w),
                _MiniBadge(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Estrellas: ${data.estrellasRachaTotal}',
                  bgColor: appColors.warmSurfaceBg,
                  fgColor: appColors.warmSurfaceFg,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: data.puedeActivarEstrellaHoy && !_activatingStreak
                    ? _activarRachaDiaria
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: appColors.progressFillCool,
                  foregroundColor: appColors.overlayOnGradient,
                  disabledBackgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Fredoka',
                  ),
                ),
                icon: _activatingStreak
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: appColors.overlayOnGradient,
                        ),
                      )
                    : const Icon(Icons.star_rounded),
                label: Text(
                  data.estrellaHoyActivada
                      ? 'Estrella de hoy ya activada'
                      : data.puedeActivarEstrellaHoy
                      ? 'Activar estrella diaria'
                      : 'Completa tu registro emocional de hoy',
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Activa tu estrella diaria para mantener la racha y sumar premios.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Fredoka',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequentMoodCard() {
    final estado = _data?.estadoAnimoMasFrecuente;

    final content = estado == null
        ? 'Aún no hay registros suficientes para detectar tu estado dominante.'
        : 'Tu estado más frecuente ha sido ${estado.nombre} (${estado.total} registros).';

    return InfoCard(
      title: 'Estado de ánimo más frecuente',
      content: content,
      icon: Icons.favorite_rounded,
      iconColor: context.appColors.dangerFg,
    );
  }

  Widget _buildFrequentEmotionsCard() {
    final emociones = _data?.emocionesFrecuentes ?? const <FrequentMood>[];

    final content = emociones.isEmpty
        ? 'No se han registrado emociones suficientes en tus sesiones.'
        : emociones.map((e) => '${e.nombre} (${e.total})').join('  •  ');

    return InfoCard(
      title: 'Emociones más frecuentes',
      content: content,
      icon: Icons.emoji_emotions_rounded,
      iconColor: context.appColors.warmBadgeFg,
    );
  }

  Widget _buildMoodEvolutionCard() {
    final evo = _data?.evolucionEstadoAnimo;
    final serie = evo?.serieUltimos7Dias ?? const <EvolutionPoint>[];

    String tendenciaTexto(String tendencia) {
      if (tendencia == 'subiendo') return 'Tu promedio de ánimo ha mejorado respecto a la semana anterior.';
      if (tendencia == 'bajando')
        return 'Tu promedio de ánimo ha bajado respecto a la semana anterior.';
      return 'Tu promedio de ánimo se mantiene estable respecto a la semana anterior.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: context.appColors.brandBorder, width: 1.5.w),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: context.appColors.brandBorder),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Evolución del estado de ánimo',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Fredoka',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            evo == null
                ? 'Aún no hay evolución para mostrar.'
                : tendenciaTexto(evo.tendencia),
            style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
          ),
          SizedBox(height: 12.h),
          if (serie.isEmpty)
            Text(
              'No se han registrado estados de ánimo en el periodo seleccionado.',
              style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
            )
          else
            SizedBox(
              height: 60.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: serie.map((point) {
                  final safe = point.promedio.clamp(0.0, 5.0);
                  final barHeight = 8.0 + (safe * 10.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: context.appColors.progressFillCool,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreativeChallengeCard() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    String reto;
    if (data.puedeActivarEstrellaHoy) {
      reto =
          'Reto del día: activa tu estrella diaria y escribe una línea en tu diario.';
    } else if (data.estrellaHoyActivada) {
      reto = 'Excelente: ya completaste tu reto de hoy. ¡Sostén la constancia!';
    } else {
      reto =
          'Te falta registrar tu estado emocional de hoy para desbloquear tu estrella.';
    }

    return InfoCard(
      title: 'Reto personal inteligente',
      content: reto,
      icon: Icons.lightbulb_rounded,
      iconColor: context.appColors.accentPurple,
    );
  }
}

class _DayItem extends StatelessWidget {
  final String day;
  final bool active;
  final bool completed;

  const _DayItem({
    required this.day,
    this.active = false,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: day,
      child: Semantics(
        label: '$day, ${active ? 'estrella activada' : completed ? 'registro completado' : 'pendiente'}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              Icon(
                Icons.star_rounded,
                color: context.appColors.progressFillWarm,
                size: 24,
              )
            else if (completed)
              Icon(
                Icons.check_circle_outline_rounded,
                color: context.appColors.progressFillCool,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _shortDay(day),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDay(String value) {
    const labels = <String, String>{
      'lunes': 'Lun',
      'martes': 'Mar',
      'miércoles': 'Mié',
      'miercoles': 'Mié',
      'jueves': 'Jue',
      'viernes': 'Vie',
      'sábado': 'Sáb',
      'sabado': 'Sáb',
      'domingo': 'Dom',
    };
    final normalized = value.trim().toLowerCase();
    if (labels.containsKey(normalized)) return labels[normalized]!;
    if (value.length <= 3) return value;
    return value.substring(0, 3);
  }
}


class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: fgColor,
              fontFamily: 'Fredoka',
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.dangerFg.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            'No se pudo cargar tu pantalla personal.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: appColors.dangerFg,
            ),
          ),
          SizedBox(height: 8.h),
          Text(error, style: TextStyle(color: appColors.dangerFg)),
          SizedBox(height: 8.h),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
