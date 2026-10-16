import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:rest/features/emotion/screens/emotionregister_screen.dart';
import 'package:rest/features/navigation/main_app.dart';
import 'package:rest/features/onboarding/screens/onboarding_status_screen.dart';
import 'package:rest/features/onboarding/services/onboarding_service.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/widgets/primary_gradient_button.dart';
import 'package:rest/features/intro_auth/widgets/star_rain_widget.dart';
import 'login_screen.dart';

class HowYouFoundScreen extends StatefulWidget {
  const HowYouFoundScreen({super.key});

  @override
  State<HowYouFoundScreen> createState() => _HowYouFoundScreenState();
}

class _HowYouFoundScreenState extends State<HowYouFoundScreen> {
  String? selectedOption;

  final List<String> options = [
    'Por redes sociales',
    'Por publicidad',
    'Por Universidad',
    'Por otras cosas...',
  ];

  Future<void> _continuar() async {
    if (selectedOption == null) return;

    // El token y userId ya vienen guardados desde RegisterScreen
    if (UserSession.authToken != null && UserSession.userId != null) {
      Widget destinationBuilder(BuildContext _) => UserSession.canDoTestToday()
          ? const EmotionRegisterScreen()
          : const MainApp();

      try {
        final onboarding = await OnboardingService().getEstado();
        if (!onboarding.completado) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingStatusScreen(
                destinationBuilder: destinationBuilder,
              ),
            ),
          );
          return;
        }
      } catch (_) {
        if (mounted) {
          AppToast.warning(
            context,
            'No pudimos consultar el onboarding. Podrás completarlo después.',
          );
        }
      }

      if (!mounted) return;
      // Validar si el usuario puede hacer el test hoy (solo una vez al día)
      if (UserSession.canDoTestToday()) {
        // Mostrar EmotionRegisterScreen si puede hacer el test
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmotionRegisterScreen()),
        );
      } else {
        // Si ya hizo el test hoy, ir a MainApp
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainApp()),
        );
      }
    } else {
      // Si por alguna razón no hay sesión, ir a login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10.h),

                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [appColors.accentPurple, appColors.accentBlue],
                          ).createShader(bounds),
                          child: Text(
                            '¡Perfecto!',
                            style: GoogleFonts.fredoka(
                              fontSize: 60.sp,
                              fontWeight: FontWeight.bold,
                              color: appColors.overlayOnGradient,
                            ),
                          ),
                        ),

                        SizedBox(height: 8.h),

                        SizedBox(
                          width: 230.w,
                          height: 230.h,
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset('assets/images/rest.png'),
                              ),
                              Positioned(
                                top: 10,
                                left: 0,
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 30.w,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 50,
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 20.w,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 50,
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 25.w,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 35.w,
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 0,
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 18.w,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 22.w,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 20,
                                child: Image.asset(
                                  'assets/images/star.png',
                                  width: 28.w,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12.h),

                        Text(
                          '¡Una última cosa!',
                          style: GoogleFonts.fredoka(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: appColors.accentPurple,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.h),

                    Text(
                      '¿Cómo supiste de mí?',
                      style: GoogleFonts.fredoka(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    ...options.map(
                      (option) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedOption = option;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: selectedOption == option
                                  ? appColors.accentTeal
                                  : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: appColors.accentTeal,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              option,
                              style: GoogleFonts.fredoka(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: selectedOption == option
                                    ? appColors.overlayOnGradient
                                    : appColors.brandBorder,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    Opacity(
                      opacity: selectedOption != null ? 1 : 0.5,
                      child: GestureDetector(
                        onTap: selectedOption != null ? _continuar : null,
                        child: PrimaryGradientButton(
                          label: 'Siguiente',
                          height: 52,
                          fontSize: 30,
                          widthFraction: 0.82,
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
          // Lluvia de estrellas por encima para que sea visible
          const Positioned.fill(
            child: StarRainWidget(
              starCount: 38,
              duration: Duration(seconds: 6),
            ),
          ),
        ],
      ),
    );
  }
}
