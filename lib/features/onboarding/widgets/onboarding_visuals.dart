import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

const onboardingPurple = Color(0xFF3A5AFF);
const onboardingViolet = Color(0xFF8C4EFF);
const onboardingMint = Color(0xFF5CCFC0);
const onboardingBlue = Color(0xFF2981C1);

class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? Theme.of(context).colorScheme.surface : null,
        gradient: dark
            ? null
            : const LinearGradient(
                colors: [Color(0xFFF3F7FF), Color(0xFFF4EEFF)],
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
    return Container(
      width: size.w,
      height: size.w,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: completed
              ? const [Color(0xFFFFECA8), Color(0xFFFFD9F1)]
              : const [Color(0xFFDDFBF7), Color(0xFFDDE7FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: (completed ? onboardingViolet : onboardingBlue).withValues(
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
              gradient: const LinearGradient(
                colors: [onboardingMint, onboardingBlue],
              ),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: onboardingBlue.withValues(alpha: 0.28),
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
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 9.w),
                        Icon(icon, color: Colors.white, size: 21.sp),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
