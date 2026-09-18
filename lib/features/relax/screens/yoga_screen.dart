import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class YogaScreen extends StatefulWidget {
  const YogaScreen({super.key});

  @override
  State<YogaScreen> createState() => _YogaScreenState();
}

class _YogaScreenState extends State<YogaScreen> {
  int _selectedLevel = 1;
  
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSessionActive = false;
  bool _isPaused = false;
  final int _totalDuration = 15; // Total aproximado de la sesión

  final List<Map<String, String>> poses = [
    {
      'name': 'Asana del Loto',
      'duration': '5 min',
      'description': 'Pose de meditación fundamental',
    },
    {
      'name': 'Cobra',
      'duration': '3 min',
      'description': 'Estira el pecho y abdomen',
    },
    {
      'name': 'Gato-Vaca',
      'duration': '4 min',
      'description': 'Calienta la columna',
    },
    {
      'name': 'Árbol',
      'duration': '3 min',
      'description': 'Mejora el equilibrio',
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      if (!_isSessionActive) {
        _remainingSeconds = _totalDuration * 60;
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
        title: Text('Namasté', style: TextStyle(fontFamily: 'Fredoka')),
        content: Text(
          'Has completado tu práctica de Yoga.\nTu mente y cuerpo te lo agradecen.',
          style: TextStyle(fontFamily: 'Fredoka'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context, true);
            },
            child: Text(
              'Finalizar práctica',
              style: TextStyle(fontFamily: 'Fredoka'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          _isSessionActive ? '🧘 En sesión' : '🧘 Yoga',
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
          ? _buildTimerView(colorScheme, isDark)
          : _buildSelectionView(colorScheme, isDark),
    );
  }

  Widget _buildSelectionView(ColorScheme colorScheme, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E3A4A) : const Color(0xFF87CEEB);
    final shadowColor = isDark 
        ? Colors.black.withValues(alpha: 0.3) 
        : const Color(0xFF87CEEB).withValues(alpha: 0.4);
    final onCardColor = isDark ? const Color(0xFF90CAF9) : Colors.white;
    final secondaryTextColor = isDark ? const Color(0xFF64B5F6) : Colors.white70;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            Text(
              'Nivel de Dificultad:',
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
              children: [
                _buildLevelButton(1, 'Principiante'),
                _buildLevelButton(2, 'Intermedio'),
                _buildLevelButton(3, 'Avanzado'),
              ],
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
                    'Sesión de Yoga Personalizada',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: onCardColor,
                      fontFamily: 'Fredoka',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Prepárate para conectar mente y cuerpo',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: secondaryTextColor,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Fredoka',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Poses para esta sesión:',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16.h),
            ...poses.map((pose) => _buildPoseCard(pose)),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                onPressed: _startTimer,
                label: 'Iniciar Sesión',
                icon: Icons.spa_rounded,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerView(ColorScheme colorScheme, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E3A4A) : const Color(0xFF87CEEB);
    final onCardColor = isDark ? const Color(0xFF90CAF9) : Colors.white;

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

  Widget _buildLevelButton(int level, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
          ),
        ),
      ),
    );
  }

  Widget _buildPoseCard(Map<String, String> pose) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pose['name']!,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⏱️ ${pose['duration']!}',
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
          SizedBox(height: 8.h),
          Text(
            pose['description']!,
            style: TextStyle(
              fontSize: 15.sp,
              fontFamily: 'Fredoka',
              color: colorScheme.onSurfaceVariant,
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
              color: isSecondary ? colorScheme.primary : Colors.white,
              size: 24,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSecondary ? colorScheme.primary : Colors.white,
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
            Icon(icon, color: Colors.white),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
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
