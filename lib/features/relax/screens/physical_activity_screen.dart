import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';

class PhysicalActivityScreen extends StatefulWidget {
  const PhysicalActivityScreen({super.key});

  @override
  State<PhysicalActivityScreen> createState() => _PhysicalActivityScreenState();
}

class _PhysicalActivityScreenState extends State<PhysicalActivityScreen> {
  int _selectedDuration = 30;
  int _burnedCalories = 0;
  
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSessionActive = false;
  bool _isPaused = false;

  final List<Map<String, dynamic>> exercises = [
    {'name': 'Correr', 'cal': 10, 'emoji': '🏃'},
    {'name': 'Nadar', 'cal': 12, 'emoji': '🏊'},
    {'name': 'Ciclismo', 'cal': 9, 'emoji': '🚴'},
    {'name': 'Caminar', 'cal': 5, 'emoji': '🚶'},
    {'name': 'Boxeo', 'cal': 14, 'emoji': '🥊'},
  ];

  @override
  void initState() {
    super.initState();
    _calculateCalories(_selectedDuration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateCalories(int duration) {
    int total = 0;
    for (var exercise in exercises) {
      total += (exercise['cal'] as int) * (duration / 10).toInt();
    }
    setState(() {
      _selectedDuration = duration;
      _burnedCalories = total;
    });
  }

  void _startTimer() {
    setState(() {
      if (!_isSessionActive) {
        _remainingSeconds = _selectedDuration * 60;
        _isSessionActive = true;
      }
      _isPaused = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _showCompletionDialog();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _timer?.cancel();
    });
  }

  void _stopTimer() {
    setState(() {
      _timer?.cancel();
      _isSessionActive = false;
      _isPaused = false;
      _remainingSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text('¡Felicidades!', style: TextStyle(fontFamily: 'Fredoka')),
        content: Text(
          'Has completado tu sesión de $_selectedDuration minutos.\n¡Excelente trabajo!',
          style: const TextStyle(fontFamily: 'Fredoka'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(fontFamily: 'Fredoka')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          _isSessionActive ? '⏱️ En sesión' : '💪 Actividad Física',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            fontFamily: 'Fredoka',
            fontSize: 22.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.primary),
          onPressed: () {
            if (_isSessionActive) {
              _stopTimer();
            }
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            color: colorScheme.outlineVariant,
            thickness: 1,
            height: 1.h,
            indent: 20,
            endIndent: 20,
          ),
        ),
      ),
      body: _isSessionActive 
          ? _buildTimerView()
          : _buildSelectionView(colorScheme),
    );
  }

  Widget _buildSelectionView(ColorScheme colorScheme) {
    final appColors = context.appColors;
    final cardColor = appColors.brandSoft;
    final shadowColor = appColors.brandSoft.withValues(alpha: 0.4);
    final onCardColor = appColors.overlayOnGradient;
    final secondaryTextColor = appColors.overlayOnGradient.withValues(alpha: 0.7);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            Text(
              'Duración de la sesión:',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [10, 20, 30, 45].map((d) => _buildDurationButton(d)).toList(),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Calorías estimadas a quemar:',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontFamily: 'Fredoka',
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '$_burnedCalories kcal',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: onCardColor,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Ejercicios disponibles:',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16.h),
            ...exercises.map((exercise) => _buildExerciseCard(exercise)),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                onPressed: _startTimer,
                label: 'Iniciar Sesión',
                icon: Icons.play_arrow_rounded,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerView() {
    final appColors = context.appColors;
    final cardColor = appColors.brandSoft;
    final onCardColor = appColors.overlayOnGradient;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 64.sp,
                      fontWeight: FontWeight.bold,
                      color: onCardColor,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                  Text(
                    'tiempo restante',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: onCardColor.withValues(alpha: 0.7),
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 60.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimerControlButton(
                  onPressed: _isPaused ? _startTimer : _pauseTimer,
                  icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: _isPaused ? 'Reanudar' : 'Pausar',
                ),
                SizedBox(width: 20.w),
                _TimerControlButton(
                  onPressed: _stopTimer,
                  icon: Icons.stop_rounded,
                  label: 'Detener',
                  isSecondary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationButton(int duration) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () => _calculateCalories(duration),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          '$duration min',
          style: TextStyle(
            color: isSelected ? context.appColors.overlayOnGradient : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Text(exercise['emoji'], style: TextStyle(fontSize: 32.sp)),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              exercise['name'],
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${exercise['cal']} kcal/min',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                fontFamily: 'Fredoka',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isSecondary;

  const _TimerControlButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSecondary ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSecondary ? colorScheme.primary : context.appColors.overlayOnGradient,
              size: 24,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSecondary ? colorScheme.primary : context.appColors.overlayOnGradient,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.appColors.overlayOnGradient),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: context.appColors.overlayOnGradient,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
