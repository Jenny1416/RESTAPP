import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/emotion_service.dart';
import 'package:rest/core/services/progress_service.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/features/progress/screens/emotional_calendar_screen.dart';
import 'package:rest/features/progress/widgets/activity_completion_sheet.dart';
import 'package:rest/features/progress/screens/streak_screen.dart';
import 'package:rest/features/relax/screens/jokes_screen.dart';
import 'package:rest/features/relax/screens/music_screen.dart';
import 'package:rest/features/relax/screens/physical_activity_screen.dart';
import 'package:rest/features/relax/screens/yoga_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  static const List<Duration> _retryDelays = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 900),
    Duration(milliseconds: 1400),
  ];
  static const Duration _cacheTtl = Duration(minutes: 3);

  static DailyActivitiesSummary? _cachedActividades;
  static List<RelaxTechnique>? _cachedTecnicas;
  static DateTime? _cachedAt;

  static bool _isCacheValid() {
    final cacheAt = _cachedAt;
    if (cacheAt == null) return false;
    if (_cachedActividades == null || _cachedTecnicas == null) return false;
    return DateTime.now().difference(cacheAt) <= _cacheTtl;
  }

  static Future<void> prefetch({bool force = false}) async {
    if (!force && _isCacheValid()) return;
    if (UserSession.authToken == null || UserSession.userId == null) {
      await UserSession.load();
    }
    if (UserSession.authToken == null || UserSession.userId == null) return;

    final service = ProgressService();
    try {
      _cachedActividades = await service.fetchActividadesDiarias();
      _cachedAt = DateTime.now();
    } catch (_) {
      // Ignore; screen will handle errors/retry
    }
    try {
      _cachedTecnicas = await service.fetchTecnicasRelajacion();
      _cachedAt = DateTime.now();
    } catch (_) {
      // Ignore; screen will handle errors/retry
    }
  }

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final EmotionService _emotionService = EmotionService();
  final ProgressService _progressService = ProgressService();

  bool _loadingWeekly = true;
  bool _loadingActivities = true;
  bool _loadingTechniques = true;
  bool _loadingRewards = true;
  int? _sendingActivityId;
  int? _sendingRewardId;

  String? _weeklyError;
  String? _activitiesError;
  String? _techniquesError;
  String? _rewardsError;

  final Map<String, num> _weeklyByDate = {};
  DailyActivitiesSummary? _actividades;
  List<RelaxTechnique> _tecnicas = const [];
  RewardsCatalogSummary? _rewardsCatalog;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool force = false}) async {
    await _ensureSessionReady();
    if (!mounted) return;

    if (UserSession.authToken == null || UserSession.userId == null) {
      setState(() {
        _loadingWeekly = false;
        _loadingActivities = false;
        _loadingTechniques = false;
        _loadingRewards = false;
        _weeklyError = 'No hay sesión activa. Inicia sesión nuevamente.';
        _activitiesError = 'No hay sesión activa. Inicia sesión nuevamente.';
        _techniquesError = 'No hay sesión activa. Inicia sesión nuevamente.';
        _rewardsError = 'No hay sesión activa. Inicia sesión nuevamente.';
      });
      return;
    }

    final shouldUseCache = !force && ProgressScreen._isCacheValid();
    if (shouldUseCache) {
      setState(() {
        _actividades = ProgressScreen._cachedActividades;
        _tecnicas = ProgressScreen._cachedTecnicas ?? const [];
        _loadingActivities = false;
        _loadingTechniques = false;
      });
    }

    await Future.wait([
      _loadWeekly(),
      if (!shouldUseCache) _loadDailyActivities(),
      if (!shouldUseCache) _loadTechniques(),
      _loadRewardsCatalog(),
    ]);
  }

  Future<void> _ensureSessionReady() async {
    if (UserSession.authToken != null && UserSession.userId != null) {
      return;
    }

    await UserSession.load();
    if (UserSession.authToken != null && UserSession.userId != null) {
      return;
    }

    for (var i = 0; i < 10; i += 1) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (UserSession.authToken != null && UserSession.userId != null) {
        return;
      }
    }
  }

  Future<void> _loadWeekly() async {
    setState(() {
      _loadingWeekly = true;
      _weeklyError = null;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = today.subtract(const Duration(days: 5));
      final end = today.add(const Duration(days: 5));

      final result = await _emotionService.fetchCalendarioEmocional(
        inicio: start,
        fin: end,
      );

      final mapped = <String, num>{};
      for (final item in result) {
        final fecha = (item['fecha'] ?? '').toString();
        final prom = item['promedio'] ?? item['promedio_emocional'];
        if (fecha.isEmpty || prom == null) continue;
        final parsed = prom is num ? prom : num.tryParse(prom.toString());
        final key = _normalizeApiDateKey(fecha);
        if (parsed != null && key != null) {
          mapped[key] = parsed;
        }
      }

      final todayKey = _toDateKey(today);
      final tomorrowKey = _toDateKey(today.add(const Duration(days: 1)));
      final hasToday = mapped.containsKey(todayKey);
      final hasTomorrow = mapped.containsKey(tomorrowKey);

      // Fallback para cuando backend viene corrido +1 día por zona horaria.
      if (!hasToday && hasTomorrow) {
        final shifted = <String, num>{};
        for (final entry in mapped.entries) {
          final shiftedKey = _shiftDateKey(entry.key, days: -1);
          shifted[shiftedKey] = entry.value;
        }
        mapped
          ..clear()
          ..addAll(shifted);
      }

      if (!mounted) return;
      setState(() {
        _weeklyByDate
          ..clear()
          ..addAll(mapped);
        _loadingWeekly = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weeklyError = e.toString();
        _loadingWeekly = false;
      });
    }
  }

  Future<void> _loadDailyActivities() async {
    setState(() {
      _loadingActivities = true;
      _activitiesError = null;
    });

    for (
      var attempt = 0;
      attempt <= ProgressScreen._retryDelays.length;
      attempt += 1
    ) {
      try {
        final data = await _progressService.fetchActividadesDiarias();
        if (!mounted) return;
        setState(() {
          _actividades = data;
          _loadingActivities = false;
        });
        ProgressScreen._cachedActividades = data;
        ProgressScreen._cachedAt = DateTime.now();
        return;
      } catch (e) {
        if (attempt < ProgressScreen._retryDelays.length && _shouldRetry(e)) {
          await Future.delayed(ProgressScreen._retryDelays[attempt]);
          continue;
        }
        if (!mounted) return;
        setState(() {
          _activitiesError = e.toString();
          _loadingActivities = false;
        });
        return;
      }
    }
  }

  Future<void> _loadTechniques() async {
    setState(() {
      _loadingTechniques = true;
      _techniquesError = null;
    });

    for (
      var attempt = 0;
      attempt <= ProgressScreen._retryDelays.length;
      attempt += 1
    ) {
      try {
        final data = await _progressService.fetchTecnicasRelajacion();
        if (!mounted) return;
        setState(() {
          _tecnicas = data;
          _loadingTechniques = false;
        });
        ProgressScreen._cachedTecnicas = data;
        ProgressScreen._cachedAt = DateTime.now();
        return;
      } catch (e) {
        if (attempt < ProgressScreen._retryDelays.length && _shouldRetry(e)) {
          await Future.delayed(ProgressScreen._retryDelays[attempt]);
          continue;
        }
        if (!mounted) return;
        setState(() {
          _techniquesError = e.toString();
          _loadingTechniques = false;
        });
        return;
      }
    }
  }

  bool _shouldRetry(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('no hay sesión activa') ||
        message.contains('failed to fetch') ||
        message.contains('socketexception') ||
        message.contains('statuscode 401') ||
        message.contains('statuscode 403') ||
        message.contains('status 401') ||
        message.contains('status 403');
  }

  Future<void> _loadRewardsCatalog() async {
    setState(() {
      _loadingRewards = true;
      _rewardsError = null;
    });

    try {
      final data = await _progressService.fetchRewardsCatalog();
      if (!mounted) return;
      setState(() {
        _rewardsCatalog = data;
        _loadingRewards = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rewardsError = e.toString();
        _loadingRewards = false;
      });
    }
  }

  Future<void> _requestReward(RewardItem reward) async {
    if (_sendingRewardId != null) return;
    setState(() => _sendingRewardId = reward.id);

    try {
      await _progressService.requestReward(premioId: reward.id);
      await _loadRewardsCatalog();
      if (!mounted) return;
      AppToast.success(
        context,
        'Solicitud enviada: ${reward.nombre}. Bienestar Universitario recibió el correo.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'No se pudo solicitar premio: $e');
    } finally {
      if (mounted) {
        setState(() => _sendingRewardId = null);
      }
    }
  }

  Future<void> _completeActivity(DailyActivity activity) async {
    if (_sendingActivityId != null) return;
    final completed = await showActivityCompletionSheet(context, activity);
    if (!mounted || completed != true) return;
    setState(() => _sendingActivityId = activity.id);

    try {
      await _progressService.completarActividadDiaria(opcionId: activity.id);
      await Future.wait([_loadDailyActivities(), _loadRewardsCatalog()]);
      if (!mounted) return;
      AppToast.success(context, 'Actividad completada: ${activity.nombre}');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'No se pudo completar: $e');
    } finally {
      if (mounted) {
        setState(() => _sendingActivityId = null);
      }
    }
  }

  Future<void> _registrarTecnicaYEntrar(
    RelaxTechnique tecnica,
    Widget screen,
  ) async {
    if (tecnica.id > 0) {
      try {
        await _progressService.registrarPracticaTecnica(opcionId: tecnica.id);
        if (!mounted) return;
        AppToast.success(context, 'Práctica registrada: ${tecnica.nombre}');
      } catch (_) {
        // Si falla el registro no bloquea navegación
      }
    }

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadAll(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 16.h),
                  _buildRachaCard(context),
                  SizedBox(height: 20.h),
                  _buildRegistroEmocional(context),
                  SizedBox(height: 24.h),
                  _buildActividadesDiarias(context),
                  SizedBox(height: 24.h),
                  _buildMiDiario(context),
                  SizedBox(height: 24.h),
                  _buildTecnicasRelajacion(context),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRachaCard(BuildContext context) {
    final streak = UserSession.streakCount;
    final goal = UserSession.goalDays;
    final goalSet = UserSession.streakGoalSet;
    final progress = goalSet ? (streak / goal).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => goalSet
                ? const StreakCelebrationScreen()
                : const GoalPickerScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFF0F4FF), Color(0xFFF5F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFCDD8FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A5AFF).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Llama
            Image.asset(
              'assets/images/RachaDaily.png',
              width: 52.w,
              height: 52.h,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        goalSet
                            ? '$streak ${streak == 1 ? "día" : "días"} de racha'
                            : 'Sin racha activa',
                        style: GoogleFonts.fredoka(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A5AFF),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      if (streak > 0)
                        Text('🔥', style: TextStyle(fontSize: 16.sp)),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  if (goalSet) ...[
                    Text(
                      'Meta: $goal días · faltan ${(goal - streak).clamp(0, goal)} días',
                      style: GoogleFonts.fredoka(
                        fontSize: 12.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE0E7FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3A5AFF),
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      'Toca para elegir tu meta y activar la racha',
                      style: GoogleFonts.fredoka(
                        fontSize: 12.sp,
                        color: const Color(0xFF8C4EFF),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF3A5AFF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 100.w,
              height: 60.h,
              decoration: const BoxDecoration(
                color: Color(0xFF87CEEB),
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/normalrest.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                '¡Hola! ${UserSession.displayName}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontFamily: 'Fredoka',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildHeaderIcon(
              imagePath: 'assets/images/config.png',
              fallback: Icons.settings,
              icon: Icons.settings,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
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
      ],
    );
  }

  Widget _buildHeaderIcon({
    required String imagePath,
    required IconData fallback,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: const BoxDecoration(
          color: Color(0xFF87CEEB),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 22)
              : Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(fallback, color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRegistroEmocional(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final quickDays = List.generate(8, (i) => today.add(Duration(days: i - 2)));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final cardTextColor = isDark
        ? colorScheme.onPrimaryContainer
        : Colors.white;
    final buttonBgColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFF7DD3E8), Color(0xFF9FE6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Registro Emocional',
                style: TextStyle(
                  fontSize: 23.sp,
                  fontWeight: FontWeight.bold,
                  color: cardTextColor,
                  fontFamily: 'Fredoka',
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmotionalCalendarScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: buttonBgColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: cardTextColor,
                        size: 16,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Ver Todo',
                        style: TextStyle(
                          color: cardTextColor,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Fredoka',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Resumen semanal rápido',
            style: TextStyle(
              color: cardTextColor,
              fontWeight: FontWeight.w600,
              fontFamily: 'Fredoka',
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: _loadingWeekly
                ? SizedBox(
                    height: 72.h,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _weeklyError != null
                ? Column(
                    children: [
                      Text(
                        'No se pudo cargar el semanal',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      TextButton(
                        onPressed: _loadWeekly,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  )
                : SizedBox(
                    height: 100.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: quickDays.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (_, index) {
                        final date = quickDays[index];
                        final key = _toDateKey(date);
                        final prom = _weeklyByDate[key];
                        final isToday =
                            date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        return _weekEmotionChip(
                          context,
                          date,
                          prom,
                          isToday: isToday,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _weekEmotionChip(
    BuildContext context,
    DateTime date,
    num? promedio, {
    required bool isToday,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayNames = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
    final hasData = promedio != null;
    final asset = hasData
        ? _assetFromPromedio(promedio)
        : 'assets/images/star.png';

    return Container(
      width: 78.w,
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? const Color(0xFF2F9FE8) : colorScheme.outlineVariant,
          width: isToday ? 1.8 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayNames[date.weekday - 1],
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              fontFamily: 'Fredoka',
            ),
          ),
          if (isToday)
            Text(
              'HOY',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                fontFamily: 'Fredoka',
              ),
            ),
          SizedBox(height: 2.h),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                asset,
                width: 30.w,
                height: 30.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.emoji_emotions),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            hasData ? promedio.toStringAsFixed(1) : '--',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              fontFamily: 'Fredoka',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActividadesDiarias(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hechas = _actividades?.hechas ?? const <DailyActivity>[];
    final pendientes = _actividades?.pendientes ?? const <DailyActivity>[];
    final estrellasHoy = _actividades?.totalHechas ?? 0;
    final metaDiaria = (_actividades?.totalObjetivoDiario ?? 5).clamp(1, 999);
    final estrellasMes = _actividades?.estrellasMesActual ?? 0;
    final metaMes = (_actividades?.metaEstrellasMesActual ?? 150).clamp(
      1,
      9999,
    );
    final progresoMes = (estrellasMes / metaMes).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis actividades diarias',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontFamily: 'Fredoka',
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: const Color(0xFF7DD3E8), width: 2),
          ),
          padding: const EdgeInsets.all(16),
          child: _loadingActivities
              ? const Center(child: CircularProgressIndicator())
              : _activitiesError != null
              ? Column(
                  children: [
                    Text(
                      'No se pudo cargar actividades',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    TextButton(
                      onPressed: _loadDailyActivities,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Progreso de hoy',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Fredoka',
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFA726),
                                size: 18,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$estrellasHoy',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFBF6D00),
                                  fontFamily: 'Fredoka',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        FilledButton.tonalIcon(
                          onPressed: _showRewardsSheet,
                          icon: const Icon(
                            Icons.card_giftcard_rounded,
                            size: 18,
                          ),
                          label: const Text('Premios'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F7FF),
                            foregroundColor: const Color(0xFF1565C0),
                            textStyle: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: estrellasHoy / metaDiaria,
                        backgroundColor: const Color(0xFFCFEDFA),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF26A69A),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '$estrellasHoy de $metaDiaria completadas hoy. Objetivo: $metaDiaria actividades por día.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFAEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE1A8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFEF8D00),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Estrellas del mes: $estrellasMes / $metaMes',
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8A5200),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progresoMes),
                            duration: const Duration(milliseconds: 850),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 12,
                                  value: value,
                                  backgroundColor: const Color(0xFFFFEFD1),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFFFB300),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const Text(
                      'Pendientes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (pendientes.isEmpty)
                      _emptyHint(
                        context,
                        'Ya completaste todas tus actividades de hoy',
                      )
                    else
                      ...pendientes
                          .take(5)
                          .map((a) => _activityItem(context, a, isDone: false)),
                    SizedBox(height: 14.h),
                    const Text(
                      'Completadas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (hechas.isEmpty)
                      _emptyHint(context, 'Aún no has completado actividades')
                    else
                      ...hechas
                          .take(5)
                          .map((a) => _activityItem(context, a, isDone: true)),
                  ],
                ),
        ),
      ],
    );
  }

  void _showRewardsSheet() {
    final catalog = _rewardsCatalog;
    final estrellasDisponibles = catalog?.estrellasDisponibles ?? 0;
    final estrellasAcumuladas = catalog?.estrellasAcumuladas ?? 0;
    final estrellasReservadas = catalog?.estrellasReservadas ?? 0;
    final rewards = catalog?.premios ?? const <RewardItem>[];
    final solicitudes = catalog?.solicitudes ?? const <RewardRequest>[];
    final ratio = estrellasAcumuladas <= 0
        ? 0.0
        : (estrellasDisponibles / estrellasAcumuladas).clamp(0, 1).toDouble();

    final premiosPendientes = solicitudes
        .where((s) => s.estado.toLowerCase() == 'pendiente')
        .map((s) => s.premioNombre.toLowerCase())
        .toSet();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Premios del mes',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    if (_loadingRewards)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_rewardsError != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No se pudo cargar catalogo de premios',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextButton(
                            onPressed: () async {
                              await _loadRewardsCatalog();
                              if (!mounted) return;
                              Navigator.pop(context);
                              _showRewardsSheet();
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acumuladas: $estrellasAcumuladas  |  Reservadas: $estrellasReservadas  |  Disponibles: $estrellasDisponibles',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: const Duration(milliseconds: 850),
                            curve: Curves.easeOutQuart,
                            builder: (_, value, __) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      minHeight: 14,
                                      value: value,
                                      backgroundColor: const Color(0xFFE9F3FB),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF2F9FE8),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Estrellas disponibles para canjear: ${(value * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 16.h),
                          if (rewards.isEmpty)
                            Text(
                              'No hay premios activos por el momento.',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            ...rewards.map((reward) {
                              final alreadyPending = premiosPendientes.contains(
                                reward.nombre.toLowerCase(),
                              );
                              return _buildRewardCard(
                                context: context,
                                reward: reward,
                                unlocked:
                                    reward.solicitarHabilitado &&
                                    !alreadyPending,
                                starsRemaining: reward.estrellasFaltantes,
                                isPending: alreadyPending,
                                onRequest: () => _requestReward(reward),
                              );
                            }),
                          if (solicitudes.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Solicitudes recientes',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            ...solicitudes
                                .take(3)
                                .map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• ${s.premioNombre} - ${s.estado.toUpperCase()}',
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRewardCard({
    required BuildContext context,
    required RewardItem reward,
    required bool unlocked,
    required int starsRemaining,
    required bool isPending,
    required VoidCallback onRequest,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? const Color(0xFF4CAF50)
              : colorScheme.outlineVariant,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8F3FF),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF1D84B5),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.nombre,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  reward.descripcion,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isPending
                      ? 'Ya tienes una solicitud pendiente para este premio'
                      : unlocked
                      ? 'Listo para canjear en Bienestar Universitario'
                      : 'Te faltan $starsRemaining estrellas',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    color: isPending
                        ? const Color(0xFF1565C0)
                        : unlocked
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF8D6E63),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: 170.w,
                  child: ElevatedButton(
                    onPressed:
                        (unlocked &&
                            !isPending &&
                            _sendingRewardId != reward.id)
                        ? onRequest
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: unlocked && !isPending
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB0BEC5),
                      disabledBackgroundColor: const Color(0xFFCFD8DC),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _sendingRewardId == reward.id
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Solicitar Premio'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${reward.estrellasRequeridas}★',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w800,
                color: Color(0xFFBF6D00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityItem(
    BuildContext context,
    DailyActivity item, {
    required bool isDone,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSendingThisItem = _sendingActivityId == item.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.circle_outlined,
            color: isDone
                ? const Color(0xFF2E7D32)
                : colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                  ),
                ),
                if (item.descripcion.isNotEmpty)
                  Text(
                    item.descripcion,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
          if (!isDone)
            ElevatedButton.icon(
              onPressed: isSendingThisItem
                  ? null
                  : () => _completeActivity(item),
              icon: isSendingThisItem
                  ? SizedBox(
                      height: 18.h,
                      width: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.star_rounded, size: 18),
              label: Text(isSendingThisItem ? 'Guardando...' : 'Realizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontFamily: 'Fredoka'),
              ),
            )
          else
            const Icon(Icons.star_rounded, color: Color(0xFFFFA726)),
        ],
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontFamily: 'Fredoka',
        ),
      ),
    );
  }

  Widget _buildMiDiario(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi diario',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontFamily: 'Fredoka',
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.miDiario),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF7DD3E8), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/dairy.jpg',
                  width: 110.w,
                  height: 90.h,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'Escribe aquí todas las cosas importantes de tu día',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTecnicasRelajacion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sourceTechniques = _buildAllowedTechniques(_tecnicas);

    final mapped = sourceTechniques.map((t) {
      final tuple = _mapTechnique(t.nombre);
      return _TechniqueCardData(
        tecnica: t,
        imagePath: tuple.$1,
        screen: tuple.$2,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis técnicas de relajación',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontFamily: 'Fredoka',
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: const Color(0xFF7DD3E8), width: 2),
          ),
          child: _loadingTechniques
              ? const Center(child: CircularProgressIndicator())
              : _techniquesError != null
              ? Column(
                  children: [
                    Text(
                      'No se pudieron cargar técnicas',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    TextButton(
                      onPressed: _loadTechniques,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              : GridView.builder(
                  itemCount: mapped.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, index) {
                    final item = mapped[index];
                    return _techniqueCard(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _techniqueCard(BuildContext context, _TechniqueCardData data) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A6EC7EE),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'API',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Color(0xFF00796B),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Fredoka',
                  ),
                ),
              ),
            ),
            Expanded(
              child: Image.asset(
                data.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.self_improvement,
                  color: Color(0xFF6BA7D9),
                  size: 42,
                ),
              ),
            ),
            Text(
              data.tecnica.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _registrarTecnicaYEntrar(data.tecnica, data.screen),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: const Color(0xFF2F9FE8),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Practicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Widget) _mapTechnique(String nombre) {
    final value = _normalizeText(nombre);
    if (value.contains('yoga')) {
      return ('assets/images/yoga.png', const YogaScreen());
    }
    if (value.contains('chiste')) {
      return ('assets/images/chistes.png', const JokesScreen());
    }
    if (value.contains('musi')) {
      return ('assets/images/musica.png', const MusicScreen());
    }
    if (value.contains('fisic') || value.contains('gim')) {
      return ('assets/images/gym.png', const PhysicalActivityScreen());
    }
    return ('assets/images/normalrest.jpg', const YogaScreen());
  }

  List<RelaxTechnique> _buildAllowedTechniques(List<RelaxTechnique> input) {
    RelaxTechnique? yoga;
    RelaxTechnique? chistes;
    RelaxTechnique? musica;
    RelaxTechnique? actividadFisica;

    for (final t in input) {
      final value = _normalizeText(t.nombre);
      if (yoga == null && value.contains('yoga')) {
        yoga = t;
      } else if (chistes == null && value.contains('chiste')) {
        chistes = t;
      } else if (musica == null && value.contains('musi')) {
        musica = t;
      } else if (actividadFisica == null &&
          (value.contains('fisic') || value.contains('gim'))) {
        actividadFisica = t;
      }
    }

    RelaxTechnique fallback(String nombre) => RelaxTechnique(
      id: 0,
      nombre: nombre,
      descripcion: 'Disponible en la app',
    );

    return [
      RelaxTechnique(
        id: yoga?.id ?? 0,
        nombre: 'Yoga',
        descripcion: yoga?.descripcion ?? 'Disponible en la app',
        imageUrl: yoga?.imageUrl,
      ),
      RelaxTechnique(
        id: chistes?.id ?? 0,
        nombre: 'Chistes',
        descripcion: chistes?.descripcion ?? 'Disponible en la app',
        imageUrl: chistes?.imageUrl,
      ),
      RelaxTechnique(
        id: actividadFisica?.id ?? 0,
        nombre: 'Actividad Física',
        descripcion:
            actividadFisica?.descripcion ??
            fallback('Actividad Física').descripcion,
        imageUrl: actividadFisica?.imageUrl,
      ),
      RelaxTechnique(
        id: musica?.id ?? 0,
        nombre: 'Escuchar Música',
        descripcion:
            musica?.descripcion ?? fallback('Escuchar Música').descripcion,
        imageUrl: musica?.imageUrl,
      ),
    ];
  }

  String? _normalizeApiDateKey(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      final local = parsed.isUtc ? parsed.toLocal() : parsed;
      return _toDateKey(DateTime(local.year, local.month, local.day));
    }

    if (clean.length >= 10) {
      final iso = clean.substring(0, 10);
      final dateOnly = DateTime.tryParse(iso);
      if (dateOnly != null) {
        return _toDateKey(dateOnly);
      }
      return iso;
    }

    return null;
  }

  String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  String _toDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _shiftDateKey(String key, {required int days}) {
    final parsed = DateTime.tryParse(key);
    if (parsed == null) return key;
    final shifted = parsed.add(Duration(days: days));
    return _toDateKey(shifted);
  }

  String _assetFromPromedio(num promedio) {
    if (promedio >= 3.3) return 'assets/images/goodrest.jpg';
    if (promedio >= 2.2) return 'assets/images/green_face.png';
    if (promedio >= 1.0) return 'assets/images/yellowrest.jpg';
    return 'assets/images/pink_face.png';
  }
}

class _TechniqueCardData {
  _TechniqueCardData({
    required this.tecnica,
    required this.imagePath,
    required this.screen,
  });

  final RelaxTechnique tecnica;
  final String imagePath;
  final Widget screen;
}
