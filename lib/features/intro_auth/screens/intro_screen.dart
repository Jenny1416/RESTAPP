import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/widgets/primary_gradient_button.dart';
import 'login_screen.dart';
import 'noa_video_stub.dart'
    if (dart.library.html) 'noa_video_web.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  // ── Video ──
  late VideoPlayerController _videoController;

  // ── Controladores ──
  late AnimationController _logoFadeCtrl;   // fade-in inicial del logo
  late AnimationController _logoMoveCtrl;   // logo sube hacia arriba
  late AnimationController _noaCtrl;        // NOA entra con scale
  late AnimationController _noaFloatCtrl;   // flotación idle continua
  late AnimationController _textCtrl;       // texto aparece
  late AnimationController _buttonCtrl;     // botón aparece
  late AnimationController _shimmerCtrl;    // shimmer del botón

  // ── Animaciones ──
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoMoveY;   // desplazamiento vertical del logo
  late Animation<double> _noaScale;
  late Animation<double> _noaFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonFade;
  late Animation<double> _buttonScale;
  late Animation<double> _shimmer;

  // ── Estado ──
  bool _showNoa = false;
  bool _showText = false;
  bool _showButton = false;
  int _typewriterIndex = 0;
  Timer? _typewriterTimer;

  static const String _greeting = '¡Hola! Soy NOA';
  static const String _subtitle = 'Tu compañero de bienestar mental';

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(
      'assets/VideosAnimaciones/VideoWelcomeNoa1.mp4',
    );
    _initAnimations();
    _startSequence();
    // El video solo funciona en móvil/desktop nativo, no en web
    if (!kIsWeb) {
      _loadVideo();
    }
  }

  // Carga e inicializa el video en background (solo móvil/desktop)
  Future<void> _loadVideo() async {
    try {
      await _videoController.initialize();
      if (!mounted) return;
      _videoController.setLooping(true);
      _videoController.setVolume(0);
      setState(() {});
      if (_showNoa) _videoController.play();
    } catch (_) {
      // Fallback: se queda la imagen estática
    }
  }

  // ── Definir todos los controladores y animaciones ──
  void _initAnimations() {
    // Logo: fade-in + scale elástico
    _logoFadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoFadeCtrl, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoFadeCtrl, curve: Curves.elasticOut),
    );

    // Logo: sube desde el centro hacia la parte superior
    _logoMoveCtrl = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );
    // El valor real de Y se calcula en build() usando el tamaño de pantalla
    _logoMoveY = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoMoveCtrl, curve: Curves.easeInOut),
    );

    // NOA: aparece con scale + fade
    _noaCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _noaScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _noaCtrl, curve: Curves.elasticOut),
    );
    _noaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _noaCtrl, curve: Curves.easeOut),
    );

    // NOA: flotación suave continua
    _noaFloatCtrl = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    // Texto
    _textCtrl = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Botón
    _buttonCtrl = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut),
    );
    _buttonScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _buttonCtrl, curve: Curves.elasticOut),
    );

    // Shimmer continuo en botón
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  // ── Secuencia principal ──
  void _startSequence() {
    // PASO 1 (300ms): Logo aparece en el centro con fade + scale
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) _logoFadeCtrl.forward();
    });

    // PASO 2 (1800ms): Logo sube con animación fluida
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {});
        _logoMoveCtrl.forward();
      }
    });

    // PASO 3 (2600ms): NOA aparece en el centro con bounce
    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() => _showNoa = true);
        _noaCtrl.forward();
        // Si el video ya estaba inicializado antes de este momento, reproducirlo
        if (_videoController.value.isInitialized) {
          _videoController.play();
        }
      }
    });

    // PASO 4 (3800ms): Texto typewriter aparece debajo de NOA
    Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        setState(() => _showText = true);
        _textCtrl.forward();
        _startTypewriter();
      }
    });

    // PASO 5 (5400ms): Botón COMENZAR aparece
    Timer(const Duration(milliseconds: 5400), () {
      if (mounted) {
        setState(() => _showButton = true);
        _buttonCtrl.forward();
      }
    });
  }

  // ── Efecto typewriter ──
  void _startTypewriter() {
    _typewriterIndex = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 52), (timer) {
      if (!mounted) { timer.cancel(); return; }
      final total = _greeting.length + _subtitle.length;
      if (_typewriterIndex < total) {
        setState(() => _typewriterIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  String get _displayGreeting {
    final i = _typewriterIndex.clamp(0, _greeting.length);
    return _greeting.substring(0, i);
  }

  String get _displaySubtitle {
    if (_typewriterIndex <= _greeting.length) return '';
    final i = (_typewriterIndex - _greeting.length).clamp(0, _subtitle.length);
    return _subtitle.substring(0, i);
  }

  // ── Navegación ──
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _videoController.dispose();
    _logoFadeCtrl.dispose();
    _logoMoveCtrl.dispose();
    _noaCtrl.dispose();
    _noaFloatCtrl.dispose();
    _textCtrl.dispose();
    _buttonCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoFadeCtrl,
          _logoMoveCtrl,
          _noaCtrl,
          _noaFloatCtrl,
          _textCtrl,
          _buttonCtrl,
          _shimmerCtrl,
          if (!kIsWeb) _videoController,
        ]),
        builder: (context, _) {
          // Logo: arranca en el centro y termina en top fijo de 50px
          final double logoStartTop = size.height / 2 - 100;
          final double logoEndTop = 50.0;
          final double logoTop = logoStartTop + (logoEndTop - logoStartTop) * _logoMoveY.value;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(color: colorScheme.surface),
              ),

              // ── LOGO REST: arranca en el centro y sube ──
              Positioned(
                left: 0,
                right: 0,
                top: logoTop,
                child: Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      'assets/images/restSalud-removebg-preview.png',
                      width: size.width * 0.62,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // ── NOA ligeramente debajo del centro ──
              if (_showNoa)
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.15),
                    child: Opacity(
                      opacity: _noaFade.value,
                      child: Transform.scale(
                        scale: _noaScale.value,
                        child: _buildNoaWidget(size),
                      ),
                    ),
                  ),
                ),

              // ── TEXTO TYPEWRITER ──
              if (_showText)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: size.height * (_showButton ? 0.225 : 0.201),
                  child: FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [appColors.infoBadgeFg, appColors.accentTeal],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              _displayGreeting,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 42.sp,
                                fontWeight: FontWeight.bold,
                                color: appColors.overlayOnGradient,
                                height: 1.05,
                              ),
                            ),
                          ),
                          if (_displaySubtitle.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              _displaySubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 19.sp,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ── BOTÓN COMENZAR ──
              if (_showButton)
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: size.height * 0.107,
                  child: FadeTransition(
                    opacity: _buttonFade,
                    child: Transform.scale(
                      scale: _buttonScale.value,
                      child: _buildShimmerButton(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Widget del video / fallback ──
  Widget _buildNoaWidget(Size size) {
    final double noaWidth = size.width * 0.82;

    // En web: usar HtmlElementView con <video> nativo del navegador
    if (kIsWeb) {
      return NoaVideoWeb(width: noaWidth, height: noaWidth);
    }

    // En móvil/desktop: usar video_player
    if (_videoController.value.isInitialized) {
      final videoAspect = _videoController.value.aspectRatio;
      return SizedBox(
        width: noaWidth,
        height: noaWidth / videoAspect,
        child: VideoPlayer(_videoController),
      );
    }

    // Fallback imagen mientras carga el video (móvil)
    return Image.asset(
      'assets/images/NoaBase.png',
      width: noaWidth,
      fit: BoxFit.contain,
    );
  }

  // ── Botón con shimmer ──
  Widget _buildShimmerButton() {
    return GestureDetector(
      onTap: _navigateToLogin,
      child: PrimaryGradientButton(
        label: 'COMENZAR',
        height: 62,
        fontSize: 26,
        shimmerValue: _shimmer.value,
      ),
    );
  }
}
