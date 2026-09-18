import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GuidedRelaxationScreen extends StatefulWidget {
  const GuidedRelaxationScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.steps,
  });

  final String title;
  final IconData icon;
  final List<String> steps;

  @override
  State<GuidedRelaxationScreen> createState() =>
      _GuidedRelaxationScreenState();
}

class _GuidedRelaxationScreenState extends State<GuidedRelaxationScreen> {
  int _currentStep = 0;

  bool get _isLastStep => _currentStep == widget.steps.length - 1;

  void _continue() {
    if (_isLastStep) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _currentStep += 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (_currentStep + 1) / widget.steps.length;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: Icon(Icons.arrow_back_rounded, color: colors.primary),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: colors.primary,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Paso ${_currentStep + 1} de ${widget.steps.length}',
                    style: TextStyle(
                      color: colors.primary,
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8.h,
                        backgroundColor: colors.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 118.w,
                height: 118.w,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 62.sp, color: colors.primary),
              ),
              SizedBox(height: 36.h),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  widget.steps[_currentStep],
                  key: ValueKey(_currentStep),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontFamily: 'Fredoka',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Tómate el tiempo que necesites antes de continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 15.sp,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: FilledButton(
                  onPressed: _continue,
                  child: Text(
                    _isLastStep ? 'FINALIZAR PRÁCTICA' : 'SIGUIENTE',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 17.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
