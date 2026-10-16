import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/theme/app_colors.dart';

class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appColors.heroGradientLavenderStart,
            appColors.heroGradientLavenderEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class OnboardingNoaBadge extends StatelessWidget {
  const OnboardingNoaBadge({
    super.key,
    this.completed = false,
    this.size = 132,
  });

  final bool completed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      width: size.w,
      height: size.w,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: completed
              ? [appColors.goldStart, appColors.goldEnd]
              : [
                  appColors.heroGradientCoolEnd,
                  appColors.heroGradientLavenderStart,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (completed ? appColors.accentPurple : appColors.brandBorder)
                .withValues(
              alpha: 0.18,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        completed
            ? 'assets/images/NoaOjosEstrellas.png'
            : 'assets/images/NoaBase.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final appColors = context.appColors;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.55,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18.r),
          child: Ink(
            height: 58.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appColors.accentTeal, appColors.brandBorder],
              ),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: appColors.brandBorder.withValues(alpha: 0.28),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 23.w,
                      height: 23.w,
                      child: CircularProgressIndicator(
                        color: appColors.overlayOnGradient,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.fredoka(
                            color: appColors.overlayOnGradient,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 9.w),
                        Icon(
                          icon,
                          color: appColors.overlayOnGradient,
                          size: 21.sp,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
