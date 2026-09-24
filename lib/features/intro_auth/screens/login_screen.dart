import 'dart:async';
import 'package:rest/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart';
import 'package:rest/core/services/auth_service.dart';
import 'package:rest/core/services/emotion_service.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/features/emotion/screens/emotionregister_screen.dart';
import 'package:rest/features/navigation/main_app.dart';
import 'package:rest/features/onboarding/screens/onboarding_status_screen.dart';
import 'package:rest/features/onboarding/services/onboarding_service.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/widgets/primary_gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _emotionService = EmotionService();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _buttonPressed = false;
  bool _joinButtonPressed = false;

  // Animaciones de entrada
  late AnimationController _entryCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _field1Fade;
  late Animation<Offset> _field1Slide;
  late Animation<double> _field2Fade;
  late Animation<Offset> _field2Slide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _bottomFade;
  late Animation<Offset> _bottomSlide;

  // Shimmer del botón
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  // Flecha del botón UNIRME
  late AnimationController _arrowCtrl;
  late Animation<double> _arrowOffset;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));

    // Controlador de entrada en cascada
    _entryCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
          ),
        );

    _field1Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );
    _field1Slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
          ),
        );

    _field2Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _field2Slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
          ),
        );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.5, 0.78, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.5, 0.78, curve: Curves.easeOut),
          ),
        );

    _bottomFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
          ),
        );

    // Shimmer continuo en botón INGRESAR
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Flecha animada en UNIRME
    _arrowCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);
    _arrowOffset = Tween<double>(
      begin: 0,
      end: 6,
    ).animate(CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut));

    // Lanzar animación de entrada
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    _arrowCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final correo = _emailController.text.trim();
    final contrasena = _passwordController.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      AppToast.warning(context, 'Ingresa correo y contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        correo: correo,
        contrasena: contrasena,
      );

      // Extraer un posible nombre desde la respuesta o usar el correo
      String nombre = correo.split('@').first;
      if (response['nombres'] is String) {
        nombre = response['nombres'];
      } else if (response['user'] is Map &&
          (response['user'] as Map)['nombres'] is String) {
        nombre = (response['user'] as Map)['nombres'] as String;
      }

      UserSession.currentUserName = nombre;

      // Guardar token e id de usuario si vienen en la respuesta
      final dynamic token =
          response['token'] ??
          response['accessToken'] ??
          response['jwt'] ??
          (response['data'] is Map ? (response['data'] as Map)['token'] : null);

      if (token is String && token.isNotEmpty) {
        UserSession.authToken = token;
      }

      // El login puede devolver user/usuario en distintos formatos (el del login viene mal)
      final dynamic user =
          response['user'] ??
          response['usuario'] ??
          (response['data'] is Map
              ? (response['data'] as Map)['user']
              : null) ??
          (response['data'] is Map
              ? (response['data'] as Map)['usuario']
              : null);

      if (user is Map) {
        final id = user['id'];
        if (id is int) {
          UserSession.userId = id;
        } else if (id is num) {
          UserSession.userId = id.toInt();
        } else if (id is String) {
          UserSession.userId = int.tryParse(id);
        }
      }
      if (UserSession.userId == null && response['id'] != null) {
        final id = response['id'];
        if (id is int) {
          UserSession.userId = id;
        } else if (id is num) {
          UserSession.userId = id.toInt();
        } else if (id is String) {
          UserSession.userId = int.tryParse(id);
        }
      }

      await UserSession.persist();

      if (!mounted) return;

      // Consultar al backend si ya existe el registro emocional de hoy
      bool yaHizoTest = false;
      try {
        yaHizoTest = await _emotionService.existeRegistroEmocionalHoy();
        if (yaHizoTest) {
          UserSession.lastTestDate = DateTime.now();
          await UserSession.persist();
        }
      } catch (e) {
        // Si falla la consulta, mostramos error y no navegamos a ciegas
        if (mounted) {
          AppToast.error(
            context,
            'No se pudo verificar el estado del test diario. Inténtalo de nuevo.',
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      try {
        final onboarding = await OnboardingService().getEstado();
        if (!onboarding.completado) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingStatusScreen(
                destinationBuilder: (_) => yaHizoTest
                    ? const MainApp()
                    : const EmotionRegisterScreen(),
              ),
            ),
          );
          return;
        }
      } catch (_) {
        if (mounted) {
          AppToast.warning(
            context,
            'No pudimos consultar el onboarding. Puedes completarlo después desde Inicio.',
          );
        }
      }

      if (!mounted) return;

      if (!yaHizoTest) {
        // Mostrar EmotionRegisterScreen si NO ha hecho el test
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EmotionRegisterScreen(),
          ),
        );
      } else {
        // Si ya hizo el test hoy, ir a MainApp
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      }
    } catch (e) {
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryCtrl, _shimmerCtrl, _arrowCtrl]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── LOGO ──
                    FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 0),
                          child: Image.asset(
                            'assets/images/restSalud-removebg-preview.png',
                            width: 200.w,
                            height: 160.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // ── CAMPO EMAIL ──
                    FadeTransition(
                      opacity: _field1Fade,
                      child: SlideTransition(
                        position: _field1Slide,
                        child: _buildAnimatedField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          label: 'Usuario o correo',
                          hint: 'example@correo.com',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                    ),

                    SizedBox(height: 18.h),

                    // ── CAMPO CONTRASEÑA ──
                    FadeTransition(
                      opacity: _field2Fade,
                      child: SlideTransition(
                        position: _field2Slide,
                        child: _buildAnimatedField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          label: 'Contraseña',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // ── OLVIDÉ CONTRASEÑA ──
                    FadeTransition(
                      opacity: _field2Fade,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.forgotPassword,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.fredoka(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: '¿Se te olvidó? ',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Recuperar →',
                                  style: TextStyle(color: appColors.accentPurple),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // ── BOTÓN INGRESAR ──
                    FadeTransition(
                      opacity: _buttonFade,
                      child: SlideTransition(
                        position: _buttonSlide,
                        child: _buildIngresarButton(),
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // ── DIVIDER ──
                    FadeTransition(
                      opacity: _bottomFade,
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: colorScheme.outlineVariant,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '¿Eres nueva/o?',
                              style: GoogleFonts.fredoka(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: colorScheme.outlineVariant,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // ── BIENVENIDA ──
                    FadeTransition(
                      opacity: _bottomFade,
                      child: SlideTransition(
                        position: _bottomSlide,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Bienvenidos a ',
                              style: GoogleFonts.fredoka(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [appColors.accentPurple, appColors.accentBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'REST',
                                style: GoogleFonts.fredoka(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: appColors.overlayOnGradient,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // ── BOTÓN UNIRME ──
                    FadeTransition(
                      opacity: _bottomFade,
                      child: SlideTransition(
                        position: _bottomSlide,
                        child: _buildUnirmeButton(),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // ── CARTEL NOA ──
                    FadeTransition(
                      opacity: _bottomFade,
                      child: SlideTransition(
                        position: _bottomSlide,
                        child: _buildNoaCard(colorScheme),
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoaCard(ColorScheme colorScheme) {
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            appColors.accentBlue.withValues(alpha: 0.08),
            appColors.accentPurple.withValues(alpha: 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(
          color: appColors.accentBlue.withValues(alpha: 0.18),
          width: 1.5.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/NoaBase.png',
            width: 60.w,
            height: 60.h,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola! Soy NOA 👋',
                  style: GoogleFonts.fredoka(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: appColors.accentPurple,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Ingresa o únete y te acompañaré en tu bienestar mental cada día.',
                  style: GoogleFonts.fredoka(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Campo con focus animado, floating label y toggle contraseña ──
  Widget _buildAnimatedField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: appColors.accentBlue.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.fredoka(
              fontSize: isFocused || hasText ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: isFocused
                  ? appColors.accentBlue
                  : colorScheme.onSurfaceVariant,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(label),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isFocused
                  ? LinearGradient(
                      colors: [appColors.accentBlue, appColors.accentPurple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : LinearGradient(
                      colors: [
                        appColors.goalCardUnselectedBorder,
                        appColors.accentPurple.withValues(alpha: 0.35),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: isPassword && !_passwordVisible,
                style: GoogleFonts.fredoka(
                  color: colorScheme.onSurface,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.fredoka(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 15.sp,
                  ),
                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      color: isFocused
                          ? appColors.accentBlue
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasText)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: AnimatedScale(
                            scale: hasText ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.elasticOut,
                            child: Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: appColors.accentBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: appColors.overlayOnGradient,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      if (isPassword)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _passwordVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                key: ValueKey(_passwordVisible),
                                color: isFocused
                                    ? appColors.accentBlue
                                    : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón INGRESAR con shimmer + scale al presionar ──
  Widget _buildIngresarButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonPressed = true),
      onTapUp: (_) {
        setState(() => _buttonPressed = false);
        if (!_isLoading) _handleLogin();
      },
      onTapCancel: () => setState(() => _buttonPressed = false),
      child: PrimaryGradientButton(
        label: 'INGRESAR',
        fontSize: 26.sp,
        isLoading: _isLoading,
        pressed: _buttonPressed,
        shimmerValue: _shimmer.value,
      ),
    );
  }

  // ── Botón UNIRME con flecha animada ──
  Widget _buildUnirmeButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _joinButtonPressed = true),
      onTapUp: (_) {
        setState(() => _joinButtonPressed = false);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const RegisterScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      onTapCancel: () => setState(() => _joinButtonPressed = false),
      child: PrimaryGradientButton(
        label: 'UNIRME',
        height: 56.h,
        widthFraction: 0.65,
        pressed: _joinButtonPressed,
        trailing: Transform.translate(
          offset: Offset(_arrowOffset.value, 0),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: context.appColors.overlayOnGradient,
            size: 22.sp,
          ),
        ),
      ),
    );
  }
}
