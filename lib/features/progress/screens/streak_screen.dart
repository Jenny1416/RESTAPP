import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/services/personal_progress_service.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
//  PUNTO DE ENTRADA PÚBLICO
//  Muestra:
//  • Si es la primera vez → GoalPickerScreen (elegir meta)
//  • Si completó el test hoy → StreakCelebrationScreen
// ─────────────────────────────────────────────────────────────
class StreakEntryScreen extends StatelessWidget {
  const StreakEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!UserSession.streakGoalSet) {
      return const GoalPickerScreen();
    }
    return const StreakCelebrationScreen();
  }
}

// ─────────────────────────────────────────────────────────────
//  1. PANTALLA DE SELECCIÓN DE META (primera vez)
// ─────────────────────────────────────────────────────────────
class GoalPickerScreen extends StatefulWidget {
  const GoalPickerScreen({super.key});

  @override
  State<GoalPickerScreen> createState() => _GoalPickerScreenState();
}

class _GoalPickerScreenState extends State<GoalPickerScreen>
    with TickerProviderStateMixin {
  int _selectedGoal = 7;
  late AnimationController _bobCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _bob;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  final List<_GoalOption> _goals = const [
    _GoalOption(days: 7,  label: '7 días',  emoji: '🌱', desc: 'El primer hábito'),
    _GoalOption(days: 14, label: '14 días', emoji: '🔥', desc: 'Ya vas en serio'),
    _GoalOption(days: 21, label: '21 días', emoji: '⚡', desc: 'Hábito en formación'),
    _GoalOption(days: 30, label: '30 días', emoji: '🏆', desc: 'Nivel experto'),
  ];

  @override
  void initState() {
    super.initState();
    _bobCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _bob       = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut));
    _entryFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _bobCtrl.dispose(); _entryCtrl.dispose(); super.dispose(); }

  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    await UserSession.saveStreakCommitmentToBackend(_selectedGoal);
    await UserSession.registerDailyCompletion();
    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => const StreakCelebrationScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Column(
              children: [
                SizedBox(height: 24.h),

                // ── Imagen llama animada ──
                AnimatedBuilder(
                  animation: _bobCtrl,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _bob.value),
                    child: Image.asset('assets/images/RachaDaily.png', width: 110.w, height: 110.h),
                  ),
                ),

                SizedBox(height: 18.h),

                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [appColors.accentBlue, appColors.accentPurple],
                  ).createShader(b),
                  child: Text('¡Empieza tu racha!',
                    style: GoogleFonts.fredoka(fontSize: 30.sp, fontWeight: FontWeight.bold, color: appColors.overlayOnGradient),
                  ),
                ),

                SizedBox(height: 6.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'Habla con NOA cada día y elige cuántos días quieres mantener tu racha.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(fontSize: 14.sp, color: appColors.neutralMutedText, height: 1.4),
                  ),
                ),

                SizedBox(height: 22.h),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _goals.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) {
                      final g = _goals[i];
                      final selected = _selectedGoal == g.days;
                      return GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedGoal = g.days); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: selected
                                ? LinearGradient(colors: [appColors.accentBlue, appColors.accentPurple])
                                : null,
                            color: selected ? null : appColors.goalCardUnselectedBg,
                            border: Border.all(
                              color: selected ? Colors.transparent : appColors.goalCardUnselectedBorder,
                              width: 1.5,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: appColors.accentBlue.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Text(g.emoji, style: TextStyle(fontSize: 26.sp)),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(g.label, style: GoogleFonts.fredoka(
                                      fontSize: 19.sp, fontWeight: FontWeight.bold,
                                      color: selected ? appColors.overlayOnGradient : appColors.goalCardUnselectedText,
                                    )),
                                    Text(g.desc, style: GoogleFonts.fredoka(
                                      fontSize: 13.sp,
                                      color: selected
                                          ? appColors.overlayOnGradient.withValues(alpha: 0.7)
                                          : appColors.neutralMutedText,
                                    )),
                                  ],
                                ),
                              ),
                              if (selected)
                                Container(
                                  width: 26.w, height: 26.h,
                                  decoration: BoxDecoration(color: appColors.overlayOnGradient, shape: BoxShape.circle),
                                  child: Icon(Icons.check_rounded, color: appColors.accentBlue, size: 16),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: GestureDetector(
                    onTap: _confirm,
                    child: Container(
                      width: double.infinity, height: 56.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [appColors.accentTeal, appColors.accentBlue]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: appColors.accentBlue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 5))],
                      ),
                      child: Center(
                        child: Text('¡Activar mi racha! 🔥',
                          style: GoogleFonts.fredoka(color: appColors.overlayOnGradient, fontSize: 19.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  2. PANTALLA DE CELEBRACIÓN DE RACHA DIARIA
// ─────────────────────────────────────────────────────────────
class StreakCelebrationScreen extends StatefulWidget {
  const StreakCelebrationScreen({super.key});

  @override
  State<StreakCelebrationScreen> createState() => _StreakCelebrationScreenState();
}

class _StreakCelebrationScreenState extends State<StreakCelebrationScreen>
    with TickerProviderStateMixin {
  List<Color> _particlePalette(AppColors appColors) => [
        appColors.accentBlue,
        appColors.accentPurple,
        appColors.accentTeal,
        appColors.goldEnd,
        appColors.goldStart,
      ];

  late AnimationController _bobCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _fillCtrl;   // animación de llenado de días
  late AnimationController _btnCtrl;

  late Animation<double> _bob;
  late Animation<double> _flameScale;
  late Animation<double> _numberScale;
  late Animation<double> _numberFade;
  late Animation<double> _fill;         // 0→1 para el llenado de días
  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;

  final List<_Particle> _particles = [];
  final PersonalProgressService _personalService = PersonalProgressService();
  bool _claimingStar = false;
  bool _canClaimStarToday = false;
  bool _starClaimedToday = false;
  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _generateParticles();

    _bobCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _entryCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fillCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _btnCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    _bob         = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut));
    _flameScale  = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _numberScale = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 1.0, curve: Curves.elasticOut)));
    _numberFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)));
    _fill        = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut));
    _btnFade     = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
    _btnSlide    = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted) _fillCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 1400), () { if (mounted) _btnCtrl.forward(); });
    _loadDailyStarState();
  }

  Future<void> _loadDailyStarState() async {
    try {
      final data = await _personalService.fetchPantallaPersonal();
      if (!mounted) return;
      setState(() {
        _canClaimStarToday = data.puedeActivarEstrellaHoy;
        _starClaimedToday = data.estrellaHoyActivada;
      });
    } catch (_) {
      // Si falla la carga, no bloqueamos la pantalla
    }
  }

  Future<void> _claimDailyStar() async {
    if (_claimingStar || !_canClaimStarToday || _starClaimedToday) return;
    setState(() => _claimingStar = true);

    try {
      final result = await _personalService.activarRachaDiaria();
      if (!mounted) return;
      if (!result.activada) {
        await _loadDailyStarState();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.mensaje)),
        );
        return;
      }
      setState(() {
        _starClaimedToday = true;
        _canClaimStarToday = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.mensaje),
          backgroundColor: context.appColors.successFg,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo reclamar la estrella diaria: $e'),
          backgroundColor: context.appColors.dangerFg,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _claimingStar = false);
      }
    }
  }

  void _generateParticles([AppColors? palette]) {
    if (_particles.isNotEmpty) return;
    final colors = _particlePalette(palette ?? AppColors.light);
    final rand = math.Random();
    for (int i = 0; i < 16; i++) {
      _particles.add(_Particle(
        x: rand.nextDouble(), y: rand.nextDouble() * 0.5,
        size: 3 + rand.nextDouble() * 5,
        color: colors[rand.nextInt(colors.length)],
        speed: 0.3 + rand.nextDouble() * 0.6,
        angle: rand.nextDouble() * math.pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _bobCtrl.dispose(); _entryCtrl.dispose(); _fillCtrl.dispose();
    _btnCtrl.dispose(); _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    HapticFeedback.mediumImpact();
    UserSession.showStreakToday = false;
    await UserSession.persist();
    if (!mounted) return;
    Navigator.pop(context);
  }

  List<_DayDot> _buildWeekDots() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final streakDays = UserSession.streakCount;
    final streakStart = todayDate.subtract(Duration(days: streakDays - 1));

    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final isToday = day == todayDate;
      final inStreak = !day.isBefore(streakStart) && !day.isAfter(todayDate);
      final isGoal = i == 6;
      return _DayDot(label: ['L', 'M', 'X', 'J', 'V', 'S', 'D'][i], isToday: isToday, completed: inStreak, isGoal: isGoal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final streak = UserSession.streakCount;
    final goal   = UserSession.goalDays;
    final remaining = (goal - streak).clamp(0, goal);
    final weekDots  = _buildWeekDots();
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    _generateParticles(appColors);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Confetti suave en fondo ──
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(_particles, _confettiCtrl.value),
              ),
            ),

            Column(
              children: [
                SizedBox(height: 20.h),

                // ── Imagen llama con bounce + scale entry ──
                AnimatedBuilder(
                  animation: Listenable.merge([_bobCtrl, _entryCtrl]),
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _bob.value),
                    child: ScaleTransition(
                      scale: _flameScale,
                      child: Image.asset('assets/images/RachaDaily.png', width: 150.w, height: 150.h),
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // ── Número de días ──
                ScaleTransition(
                  scale: _numberScale,
                  child: FadeTransition(
                    opacity: _numberFade,
                    child: ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [appColors.accentBlue, appColors.accentPurple],
                      ).createShader(b),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('$streak',
                          style: GoogleFonts.fredoka(fontSize: 90.sp, fontWeight: FontWeight.bold, color: appColors.overlayOnGradient, height: 1.0)),
                      ),
                    ),
                  ),
                ),

                FadeTransition(
                  opacity: _numberFade,
                  child: Text(
                    streak == 1 ? 'día de racha 🔥' : 'días de racha 🔥',
                    style: GoogleFonts.fredoka(fontSize: 20.sp, color: appColors.accentPurple, fontWeight: FontWeight.w700),
                  ),
                ),

                SizedBox(height: 28.h),

                // ── Días de la semana con animación de llenado ──
                AnimatedBuilder(
                  animation: _fillCtrl,
                  builder: (_, __) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: weekDots.asMap().entries.map((e) {
                            final i = e.key;
                            final d = e.value;
                            // Cada dot se llena secuencialmente
                            final dotProgress = (_fill.value * 7 - i).clamp(0.0, 1.0);
                            return _AnimatedDayDot(dot: d, fillProgress: dotProgress);
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      if (remaining > 0)
                        RichText(text: TextSpan(
                          style: GoogleFonts.fredoka(fontSize: 14.sp, color: appColors.neutralMutedText),
                          children: [
                            const TextSpan(text: 'Alcanza tu próximo objetivo en '),
                            TextSpan(text: '$remaining ${remaining == 1 ? "día" : "días"}',
                              style: TextStyle(color: appColors.accentBlue, fontWeight: FontWeight.bold)),
                          ],
                        ))
                      else
                        Text('🏆 ¡Meta alcanzada! ¡Eres increíble!',
                          style: GoogleFonts.fredoka(fontSize: 15.sp, color: appColors.accentPurple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Barra de progreso hacia la meta ──
                FadeTransition(
                  opacity: _numberFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tu meta: $goal días',
                              style: GoogleFonts.fredoka(fontSize: 13.sp, color: appColors.neutralMutedText)),
                            Text('$streak/$goal',
                              style: GoogleFonts.fredoka(fontSize: 13.sp, color: appColors.accentBlue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedBuilder(
                            animation: _fillCtrl,
                            builder: (_, __) => LinearProgressIndicator(
                              value: (streak / goal).clamp(0.0, 1.0) * _fill.value,
                              minHeight: 10,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(appColors.accentBlue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── Botón ──
                SlideTransition(
                  position: _btnSlide,
                  child: FadeTransition(
                    opacity: _btnFade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _canClaimStarToday && !_starClaimedToday && !_claimingStar
                                ? _claimDailyStar
                                : null,
                            child: Container(
                              width: double.infinity,
                              height: 52.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [appColors.goldStart, appColors.goldEnd],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: appColors.goldEnd.withValues(alpha: 0.28),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _claimingStar
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: appColors.overlayOnGradient,
                                        ),
                                      )
                                    : Text(
                                        _starClaimedToday
                                            ? 'ESTRELLA DIARIA YA RECLAMADA ⭐'
                                            : _canClaimStarToday
                                            ? 'RECLAMAR ESTRELLA DIARIA ⭐'
                                            : 'COMPLETA TU REGISTRO PARA RECLAMAR ⭐',
                                        style: GoogleFonts.fredoka(
                                          color: appColors.overlayOnGradient,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              width: double.infinity, height: 56.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [appColors.accentTeal, appColors.accentBlue]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: appColors.accentBlue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 5))],
                              ),
                              child: Center(
                                child: Text('MANTENER MI COMPROMISO 🔥',
                                  style: GoogleFonts.fredoka(color: appColors.overlayOnGradient, fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          GestureDetector(
                            onTap: _dismiss,
                            child: Text('Continuar',
                              style: GoogleFonts.fredoka(color: appColors.neutralMutedText, fontSize: 13.sp,
                                decoration: TextDecoration.underline, decorationColor: appColors.neutralMutedText)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WIDGET DOT ANIMADO — llenado con flamita
// ─────────────────────────────────────────────────────────────
class _AnimatedDayDot extends StatelessWidget {
  final _DayDot dot;
  final double fillProgress; // 0.0 → 1.0

  const _AnimatedDayDot({required this.dot, required this.fillProgress});

  @override
  Widget build(BuildContext context) {
    final fillOpacity = fillProgress.clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label del día
        Text(
          dot.label,
          style: GoogleFonts.fredoka(
            fontSize: 12.sp,
            color: dot.isToday ? appColors.accentBlue : colorScheme.onSurfaceVariant,
            fontWeight: dot.isToday ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        SizedBox(height: 5.h),

        // Círculo con llenado + flamita
        SizedBox(
          width: 40.w, height: 40.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fondo del círculo
              Container(
                width: 40.w, height: 40.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: dot.isToday ? appColors.accentBlue.withValues(alpha: 0.4) : colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
              ),

              // Llenado progresivo (clip desde abajo)
              if (dot.completed)
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: fillOpacity,
                    child: Container(
                      width: 40.w, height: 40.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [appColors.accentTeal, appColors.accentBlue],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                ),

              // Contenido interior: flamita si completado hoy, check si pasado, número si pendiente
              if (dot.completed && fillOpacity > 0.5)
                Opacity(
                  opacity: ((fillOpacity - 0.5) * 2).clamp(0.0, 1.0),
                  child: dot.isToday
                      ? Image.asset('assets/images/RachaDaily.png', width: 26.w, height: 26.h)
                      : Icon(Icons.check_rounded, color: appColors.overlayOnGradient, size: 18),
                )
              else if (!dot.completed && dot.isGoal && !dot.isToday)
                Text('🎯', style: TextStyle(fontSize: 16.sp))
              else if (!dot.completed)
                Container(), // vacío
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAINTER DE PARTÍCULAS
// ─────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (t * p.speed + p.angle / (math.pi * 2)) % 1.0;
      final opacity = (math.sin(progress * math.pi)).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.18);
      final x = (p.x + math.cos(p.angle) * progress * 0.3) * size.width;
      final y = (p.y + math.sin(p.angle + t * 2) * 0.08) * size.height;
      canvas.drawCircle(Offset(x, y), p.size * opacity, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─────────────────────────────────────────────────────────────
//  MODELOS INTERNOS
// ─────────────────────────────────────────────────────────────
class _GoalOption {
  final int days;
  final String label;
  final String emoji;
  final String desc;
  const _GoalOption({required this.days, required this.label, required this.emoji, required this.desc});
}

class _DayDot {
  final String label;
  final bool isToday;
  final bool completed;
  final bool isGoal;
  const _DayDot({required this.label, required this.isToday, required this.completed, required this.isGoal});
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double angle;
  const _Particle({required this.x, required this.y, required this.size, required this.color, required this.speed, required this.angle});
}
