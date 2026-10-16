import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:rest/core/constants/profile_options.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'how_you_found_screen.dart';
import 'package:rest/core/services/auth_service.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/widgets/primary_gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _pageController = PageController();

  // ── Focus nodes ──
  final _nombreFocus = FocusNode();
  final _apellidoFocus = FocusNode();
  final _correoFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _telefonoFocus = FocusNode();

  // ── Dropdowns ──
  String? _edadSeleccionada;
  String? _ciudadSeleccionada;
  String? _carreraSeleccionada;
  String? _semestresSeleccionado;
  String? _sexoSeleccionado;

  // ── Estado ──
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  int _currentStep = 0;
  bool _showSuccess = false;
  bool _termsAccepted = false;
  bool _termsScrolledToBottom = false;
  final ScrollController _termsScrollCtrl = ScrollController();

  late AnimationController _checkboxCtrl;
  late Animation<double> _checkboxScale;

  // ── Animaciones ──
  late AnimationController _pageEntryCtrl;
  late Animation<Offset> _pageSlide;
  late Animation<double> _pageFade;

  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkFade;

  late AnimationController _progressCtrl;
  late Animation<double> _progressValue;

  late AnimationController _successCtrl;
  late Animation<double> _successFade;
  late Animation<double> _noaScale;
  late Animation<Offset> _noaSlide;
  late Animation<double> _textFade;

  late AnimationController _noaBounceCtrl;
  late Animation<double> _noaBounce;

  final _authService = AuthService();

  // Listas para los dropdowns
  final List<String> _edades = List.generate(56, (i) => (i + 15).toString());
  final List<String> _ciudades = ProfileOptions.cities;
  final List<String> _carreras = [
    // 🎓 PREGRADOS
    // ⚖️ Derecho y ciencias sociales
    'Derecho',
    'Ciencia Política',
    'Trabajo Social',
    'Comunicación Social y Periodismo',
    // 💰 Ciencias económicas, administrativas y contables
    'Administración de Empresas',
    'Contaduría Pública',
    'Economía',
    'Negocios Internacionales',
    'Mercadeo',
    'Administración de Negocios',
    // 🏥 Ciencias de la salud
    'Medicina',
    'Enfermería',
    'Bacteriología',
    'Instrumentación Quirúrgica',
    'Fisioterapia',
    // ⚙️ Ingeniería y tecnología
    'Ingeniería Industrial',
    'Ingeniería de Sistemas',
    'Ingeniería Civil',
    'Ingeniería Ambiental',
    'Ingeniería Mecánica',
    'Ingeniería en Ciencia de Datos',
    // 🧪 Ciencias básicas
    'Microbiología',
    'Biología',
    // 📚 Educación
    'Licenciatura en Español e Inglés',

    // 📌 ESPECIALIZACIONES
    // ⚖️ Derecho
    'Esp. Derecho Administrativo',
    'Esp. Derecho Constitucional',
    'Esp. Derecho Penal',
    'Esp. Derecho Procesal',
    'Esp. Derecho Laboral',
    'Esp. Derecho Comercial',
    'Esp. Derecho Tributario',
    'Esp. Derecho Médico',
    'Esp. Derecho de Familia',
    // 💼 Administración / negocios
    'Esp. Alta Gerencia',
    'Esp. Gerencia de Proyectos',
    'Esp. Gerencia Tributaria',
    'Esp. Gerencia Financiera',
    'Esp. Gerencia del Talento Humano',
    'Esp. Gerencia de Mercadeo',
    // 🏥 Salud
    'Esp. Gerencia de Servicios de Salud',
    'Esp. Seguridad y Salud en el Trabajo',
    'Esp. Medicina Interna',
    'Esp. Pediatría',
    'Esp. Cirugía General',
    'Esp. Dermatología',
    // ⚙️ Ingeniería
    'Esp. Gerencia Ambiental',
    'Esp. Gestión de la Calidad',
    'Esp. Seguridad Industrial',

    // 🎓 MAESTRÍAS
    // ⚖️ Derecho
    'Maestría en Derecho',
    'Maestría en Derecho Administrativo',
    'Maestría en Derecho Penal',
    'Maestría en Derecho Procesal',
    // 💼 Administración / economía
    'MBA (Administración de Empresas)',
    'Maestría en Administración',
    'Maestría en Gestión de Proyectos',
    'Maestría en Finanzas',
    'Maestría en Economía',
    // 🏥 Salud
    'Maestría en Seguridad y Salud en el Trabajo',
    // 📚 Educación
    'Maestría en Educación',

    // 🏆 DOCTORADOS
    'Doctorado en Derecho',
    'Doctorado en Derecho Administrativo',
    'Doctorado en Filosofía del Derecho y Teoría Jurídica',
  ];
  final List<String> _semestres = ProfileOptions.semesters;
  final List<String> _sexos = [
    'Femenino',
    'Masculino',
    'Otro',
    'Prefiero no decir',
  ];

  static const Map<String, String> _sexoCodes = {
    'Masculino': 'M',
    'Femenino': 'F',
    'Otro': 'O',
    'Prefiero no decir': 'N',
  };

  @override
  void initState() {
    super.initState();
    for (final n in [_nombreFocus, _apellidoFocus, _correoFocus, _passwordFocus, _telefonoFocus]) {
      n.addListener(() => setState(() {}));
    }
    for (final c in [_nombreController, _apellidoController, _correoController, _passwordController, _telefonoController, _fechaNacimientoController]) {
      c.addListener(() => setState(() {}));
    }

    _pageEntryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pageSlide = Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageEntryCtrl, curve: Curves.easeOut));
    _pageFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _pageEntryCtrl, curve: Curves.easeOut));
    _pageEntryCtrl.forward();

    _checkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    _checkFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _checkCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)));

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _progressValue = Tween<double>(begin: 0, end: 1.0 / 3.0)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward();

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _successFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _successCtrl, curve: const Interval(0, 0.3, curve: Curves.easeOut)));
    _noaSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _successCtrl, curve: const Interval(0.1, 0.55, curve: Curves.easeOutBack)));
    _noaScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _successCtrl, curve: const Interval(0.1, 0.55, curve: Curves.easeOutBack)));
    _textFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _successCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _noaBounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _noaBounce = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _noaBounceCtrl, curve: Curves.easeInOut));

    _checkboxCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _checkboxScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _checkboxCtrl, curve: Curves.elasticOut));

    _termsScrollCtrl.addListener(() {
      if (!_termsScrolledToBottom && _termsScrollCtrl.hasClients) {
        final max = _termsScrollCtrl.position.maxScrollExtent;
        final current = _termsScrollCtrl.offset;
        if (max > 0 && current >= max - 20) {
          setState(() => _termsScrolledToBottom = true);
          _checkboxCtrl.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    _pageController.dispose();
    _termsScrollCtrl.dispose();
    _checkboxCtrl.dispose();
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _correoFocus.dispose();
    _passwordFocus.dispose();
    _telefonoFocus.dispose();
    _pageEntryCtrl.dispose();
    _checkCtrl.dispose();
    _progressCtrl.dispose();
    _successCtrl.dispose();
    _noaBounceCtrl.dispose();
    super.dispose();
  }

  // ── Validación por paso ──
  String? _validateStep(int step) {
    if (step == 0) {
      if (_nombreController.text.trim().isEmpty) return 'Ingresa tu nombre';
      if (_apellidoController.text.trim().isEmpty) return 'Ingresa tus apellidos';
      if (_edadSeleccionada == null) return 'Selecciona tu edad';
      if (_fechaNacimientoController.text.trim().isEmpty) return 'Selecciona tu fecha de nacimiento';
      if (_sexoSeleccionado == null) return 'Selecciona tu sexo';
    } else if (step == 1) {
      if (_ciudadSeleccionada == null) return 'Selecciona tu ciudad';
      if (_carreraSeleccionada == null) return 'Selecciona tu carrera';
      if (_semestresSeleccionado == null) return 'Selecciona tu semestre';
      if (_telefonoController.text.trim().isEmpty) return 'Ingresa tu teléfono';
      final phoneRegExp = RegExp(r'^\d+$');
      if (!phoneRegExp.hasMatch(_telefonoController.text.trim()) || _telefonoController.text.trim().length <= 6) {
        return 'El teléfono debe tener solo números y más de 6 dígitos';
      }
    } else if (step == 2) {
      if (_correoController.text.trim().isEmpty) return 'Ingresa tu correo';
      final emailRegExp = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$', caseSensitive: false);
      if (!emailRegExp.hasMatch(_correoController.text.trim())) return 'Ingresa un correo válido';
      if (_passwordController.text.trim().isEmpty) return 'Ingresa tu contraseña';
      if (_passwordController.text.trim().length <= 8) return 'La contraseña debe tener más de 8 caracteres';
      if (!_termsAccepted) return 'Debes aceptar los Términos y Condiciones para continuar';
    }
    return null;
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    _pageEntryCtrl.forward(from: 0);
    final target = (step + 1) / 3.0;
    _progressValue = Tween<double>(begin: _progressValue.value, end: target)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward(from: 0);
  }

  void _nextStep() {
    final error = _validateStep(_currentStep);
    if (error != null) { AppToast.warning(context, error); return; }
    _checkCtrl.forward(from: 0);
    Timer(const Duration(milliseconds: 500), () {
      if (_currentStep < 2) {
        _goToStep(_currentStep + 1);
      } else {
        _handleRegister();
      }
    });
  }

  void _prevStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _mapSexoToCode(String? sexoLabel) {
    if (sexoLabel == null || sexoLabel.isEmpty) return null;
    return _sexoCodes[sexoLabel];
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    final nombres = _nombreController.text.trim();
    final apellidos = _apellidoController.text.trim();
    final correo = _correoController.text.trim();
    final contrasena = _passwordController.text.trim();
    final ciudad = _ciudadSeleccionada!;
    final telefono = _telefonoController.text.trim();
    final edad = int.tryParse(_edadSeleccionada ?? '')!;
    final semestreActual = _semestresSeleccionado!;
    final sexo = _mapSexoToCode(_sexoSeleccionado)!;
    final fechaNacimiento = _fechaNacimientoController.text.trim();

    try {
      final response = await _authService.register(
        correo: correo,
        contrasena: contrasena,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        ciudad: ciudad,
        edad: edad,
        semestreActual: semestreActual,
        sexo: sexo,
        fechaNacimiento: fechaNacimiento,
      );

      UserSession.currentUserName = nombres;

      final dynamic token =
          response['token'] ?? response['accessToken'] ?? response['jwt'] ??
          (response['data'] is Map ? (response['data'] as Map)['token'] : null);
      if (token is String && token.isNotEmpty) UserSession.authToken = token;

      final dynamic user = response['user'] ??
          (response['data'] is Map ? (response['data'] as Map)['user'] : null);
      if (user is Map && user['id'] is int) {
        UserSession.userId = user['id'] as int;
      } else if (response['id'] is int) {
        UserSession.userId = response['id'] as int;
      }

      UserSession.lastTestDate = null;
      await UserSession.persist();

      if (!mounted) return;
      setState(() { _isLoading = false; _showSuccess = true; });
      _successCtrl.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, e.toString());
      }
    }
  }

  // ── BUILD PRINCIPAL ──
  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _buildSuccessScreen();
    if (_isLoading) return _buildLoadingScreen();
    return _buildCarousel();
  }

  // ── PANTALLA DE CARGA ──
  Widget _buildLoadingScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/NoaBase.png', width: 100.w, height: 100.h),
            SizedBox(height: 24.h),
            SizedBox(
              width: 40.w, height: 40.h,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(appColors.accentBlue),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Creando tu perfil...',
              style: GoogleFonts.fredoka(
                fontSize: 20.sp, fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PANTALLA ÉXITO NOA ──
  Widget _buildSuccessScreen() {
    final nombre = _nombreController.text.trim();
    final appColors = context.appColors;
    return AnimatedBuilder(
      animation: _successCtrl,
      builder: (_, __) => Scaffold(
        body: Container(
          width: double.infinity, height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                appColors.heroGradientLavenderStart,
                appColors.heroGradientLavenderEnd,
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _successFade,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── NOA animada ──
                  SlideTransition(
                    position: _noaSlide,
                    child: ScaleTransition(
                      scale: _noaScale,
                      child: AnimatedBuilder(
                        animation: _noaBounceCtrl,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _noaBounce.value),
                          child: child,
                        ),
                        child: Image.asset(
                          'assets/images/NoaOjosEstrellas.png',
                          width: 160.w, height: 160.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                            colors: [appColors.accentBlue, appColors.accentPurple],
                          ).createShader(b),
                          child: Text(
                            '¡Bienvenido/a, $nombre! 🎉',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 28.sp, fontWeight: FontWeight.bold,
                              color: appColors.overlayOnGradient,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Text(
                            'Estoy muy feliz de acompañarte en tu bienestar mental. ¡Juntos lo haremos increíble!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 16.sp, fontWeight: FontWeight.w500,
                              color: appColors.neutralMutedText, height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, a, __) => const HowYouFoundScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          ),
                          child: PrimaryGradientButton(
                            label: '¡Empecemos! →',
                            height: 56,
                            fontSize: 22,
                            widthFraction: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── CARRUSEL 3 PASOS ──
  Widget _buildCarousel() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final steps = [
      _StepMeta(emoji: '👤', title: '¿Quién eres?', subtitle: 'Cuéntame un poco sobre ti'),
      _StepMeta(emoji: '🎓', title: '¿Dónde estudias?', subtitle: 'Tu información académica'),
      _StepMeta(emoji: '🔐', title: 'Tu cuenta', subtitle: 'Datos para ingresar a REST'),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_progressCtrl, _checkCtrl, _pageEntryCtrl]),
          builder: (_, __) => Column(
            children: [
              // ── HEADER ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      GestureDetector(
                        onTap: _prevStep,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40.w, height: 40.h,
                          decoration: BoxDecoration(
                            color: appColors.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.arrow_back_ios_rounded,
                              color: appColors.accentBlue, size: 18),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40.w, height: 40.h,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.close_rounded,
                              color: colorScheme.onSurfaceVariant, size: 20),
                        ),
                      ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paso ${_currentStep + 1} de 3',
                            style: GoogleFonts.fredoka(
                              fontSize: 12.sp, fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          // ── TIMELINE PROGRESS ──
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressValue.value,
                              minHeight: 6,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(appColors.accentBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // ── DOTS ──
                    Row(
                      children: List.generate(3, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(left: 5),
                        width: i == _currentStep ? 20 : 8,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: i <= _currentStep
                              ? appColors.accentBlue
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              // ── TÍTULO DE PASO ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _pageFade,
                  child: SlideTransition(
                    position: _pageSlide,
                    child: Row(
                      children: [
                        Text(steps[_currentStep].emoji,
                            style: TextStyle(fontSize: 28.sp)),
                        SizedBox(width: 10.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[_currentStep].title,
                              style: GoogleFonts.fredoka(
                                fontSize: 22.sp, fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              steps[_currentStep].subtitle,
                              style: GoogleFonts.fredoka(
                                fontSize: 13.sp, color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // ── PÁGINAS ──
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),

              // ── BOTÓN SIGUIENTE / CHECK ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Botón principal
                    GestureDetector(
                      onTap: _nextStep,
                      child: AnimatedOpacity(
                        opacity: _checkCtrl.isAnimating ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: PrimaryGradientButton(
                          label: _currentStep < 2 ? 'Continuar' : 'Crear mi cuenta',
                          height: 58,
                          fontSize: 20,
                          trailing: Icon(
                            Icons.arrow_forward_rounded,
                            color: appColors.overlayOnGradient,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Check animado al avanzar
                    if (_checkCtrl.isAnimating || _checkCtrl.value > 0 && _checkCtrl.value < 1)
                      ScaleTransition(
                        scale: _checkScale,
                        child: FadeTransition(
                          opacity: _checkFade,
                          child: Container(
                            width: 58.w, height: 58.h,
                            decoration: BoxDecoration(
                              color: appColors.successFg, shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded,
                                color: appColors.overlayOnGradient, size: 32),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PASO 1: ¿Quién eres? ──
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _field('¿Cómo te llamas?', 'Tu nombre', _nombreController, _nombreFocus),
          SizedBox(height: 14.h),
          _field('Apellidos', 'Tus apellidos', _apellidoController, _apellidoFocus),
          SizedBox(height: 14.h),
          _dropdown('¿Cuántos años tienes?', 'Selecciona tu edad',
              _edadSeleccionada, _edades, (v) => setState(() => _edadSeleccionada = v)),
          SizedBox(height: 14.h),
          _datePicker(),
          SizedBox(height: 14.h),
          _dropdown('¿Con qué sexo te identificas?', 'Selecciona una opción',
              _sexoSeleccionado, _sexos, (v) => setState(() => _sexoSeleccionado = v)),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // ── PASO 2: ¿Dónde estudias? ──
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _dropdown('¿De qué ciudad eres?', 'Selecciona tu ciudad',
              _ciudadSeleccionada, _ciudades, (v) => setState(() => _ciudadSeleccionada = v)),
          SizedBox(height: 14.h),
          _dropdown('¿Cuál es tu carrera?', 'Selecciona tu carrera',
              _carreraSeleccionada, _carreras, (v) => setState(() => _carreraSeleccionada = v)),
          SizedBox(height: 14.h),
          _dropdown('¿Qué semestre cursas?', 'Selecciona el semestre',
              _semestresSeleccionado, _semestres, (v) => setState(() => _semestresSeleccionado = v)),
          SizedBox(height: 14.h),
          _field('Teléfono', '3001234567', _telefonoController, _telefonoFocus,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // ── PASO 3: Tu cuenta ──
  Widget _buildStep3() {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Correo institucional', 'example@correo.com',
              _correoController, _correoFocus,
              keyboardType: TextInputType.emailAddress),
          SizedBox(height: 14.h),
          _field('Contraseña', '••••••••', _passwordController, _passwordFocus,
              isPassword: true),
          SizedBox(height: 4.h),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: context.appColors.accentPurple),
                SizedBox(width: 5.w),
                Text('Mínimo 9 caracteres',
                    style: GoogleFonts.fredoka(fontSize: 12.sp, color: context.appColors.accentPurple, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          SizedBox(height: 18.h),

          // ── BLOQUE TÉRMINOS Y CONDICIONES ──
          _buildTermsBlock(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTermsBlock(ColorScheme colorScheme) {
    final appColors = context.appColors;
    return AnimatedBuilder(
      animation: _checkboxCtrl,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header T&C
          Row(
            children: [
              Container(
                width: 28.w, height: 28.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [appColors.accentBlue, appColors.accentPurple]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.gavel_rounded, color: appColors.overlayOnGradient, size: 16),
              ),
              SizedBox(width: 8.w),
              Text('Términos y Condiciones',
                  style: GoogleFonts.fredoka(
                    fontSize: 15.sp, fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  )),
              const Spacer(),
              if (!_termsScrolledToBottom)
                Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                    SizedBox(width: 3.w),
                    Text('Desliza', style: GoogleFonts.fredoka(
                      fontSize: 11.sp, color: colorScheme.onSurfaceVariant,
                    )),
                  ],
                )
              else
                Text('✓ Leídos', style: GoogleFonts.fredoka(
                  fontSize: 11.sp, color: appColors.successFg, fontWeight: FontWeight.bold,
                )),
            ],
          ),
          SizedBox(height: 8.h),

          // Caja de T&C scrolleable
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 180.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _termsScrolledToBottom
                    ? appColors.successFg.withValues(alpha: 0.6)
                    : appColors.accentBlue.withValues(alpha: 0.2),
                width: 1.5,
              ),
              color: colorScheme.surfaceContainerLow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Scrollbar(
                controller: _termsScrollCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _termsScrollCtrl,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _termsText,
                    style: GoogleFonts.fredoka(
                      fontSize: 13.sp, color: colorScheme.onSurface,
                      height: 1.6, fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Checkbox animado (se desbloquea al llegar al fondo)
          GestureDetector(
            onTap: _termsScrolledToBottom
                ? () => setState(() => _termsAccepted = !_termsAccepted)
                : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _termsScrolledToBottom ? 1.0 : 0.35,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox animado
                  ScaleTransition(
                    scale: _termsScrolledToBottom
                        ? (_termsAccepted
                            ? const AlwaysStoppedAnimation(1.0)
                            : _checkboxScale)
                        : const AlwaysStoppedAnimation(0.7),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 26.w, height: 26.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: _termsAccepted
                            ? LinearGradient(
                                colors: [appColors.successFg, appColors.accentTeal])
                            : null,
                        border: _termsAccepted
                            ? null
                            : Border.all(
                                color: _termsScrolledToBottom
                                    ? appColors.accentBlue
                                    : colorScheme.onSurfaceVariant,
                                width: 2),
                        color: _termsAccepted ? null : Colors.transparent,
                        boxShadow: _termsAccepted
                            ? [BoxShadow(
                                color: appColors.successFg.withValues(alpha: 0.35),
                                blurRadius: 8, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: _termsAccepted
                          ? Icon(Icons.check_rounded, color: appColors.overlayOnGradient, size: 16)
                          : null,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.fredoka(
                          fontSize: 13.sp, color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'He leído y acepto los '),
                          TextSpan(
                            text: 'Términos y Condiciones',
                            style: TextStyle(
                              color: appColors.accentBlue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' de REST Salud Mental'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hint si aún no ha scrolleado
          if (!_termsScrolledToBottom) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                SizedBox(width: 4.w),
                Text('Lee los términos para desbloquear',
                    style: GoogleFonts.fredoka(
                      fontSize: 11.sp, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const String _termsText = '''
TÉRMINOS Y CONDICIONES DE USO — REST SALUD MENTAL

Última actualización: Junio 2025

Bienvenido/a a REST, una aplicación de apoyo al bienestar emocional y salud mental dirigida a estudiantes universitarios.

1. ACEPTACIÓN DE TÉRMINOS
Al crear una cuenta y usar esta aplicación, aceptas quedar vinculado/a por estos Términos y Condiciones. Si no estás de acuerdo con alguna parte, te pedimos que no uses la aplicación.

2. USO DE LA APLICACIÓN
REST es una herramienta de apoyo complementario al bienestar mental. No reemplaza servicios clínicos, diagnósticos médicos ni tratamientos psicológicos profesionales. En caso de crisis o emergencia, comunícate con un profesional de salud mental.

3. PRIVACIDAD Y DATOS PERSONALES
Tus datos personales (nombre, correo, edad, carrera, etc.) serán usados exclusivamente para personalizar tu experiencia dentro de la aplicación. No compartiremos tu información con terceros sin tu consentimiento explícito. Consulta nuestra Política de Privacidad para más detalles.

4. CONFIDENCIALIDAD
La información que compartes con NOA (nuestro asistente de bienestar) es tratada con estricta confidencialidad y solo se usa para mejorar tu experiencia dentro de la app.

5. CONTENIDO GENERADO POR EL USUARIO
Al escribir en el diario o chat, eres responsable del contenido que compartes. REST se reserva el derecho de suspender cuentas que hagan uso indebido de la plataforma.

6. LIMITACIÓN DE RESPONSABILIDAD
REST y su equipo de desarrollo no se hacen responsables por decisiones tomadas con base en el contenido de la aplicación. Siempre recomendamos consultar con profesionales de salud mental calificados.

7. MODIFICACIONES
Podemos actualizar estos términos en cualquier momento. Te notificaremos a través de la aplicación cuando haya cambios relevantes.

8. CONTACTO
¿Tienes preguntas? Escríbenos a: soporte@restsaludmental.app

Al aceptar, confirmas que tienes al menos 15 años de edad y que has leído y comprendido estos términos en su totalidad.
''';


  // ── CAMPO DE TEXTO ANIMADO ──
  Widget _field(
    String label, String hint,
    TextEditingController controller, FocusNode focusNode, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> inputFormatters = const [],
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final isFocused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isFocused ? [
          BoxShadow(color: appColors.accentBlue.withValues(alpha: 0.2),
              blurRadius: 14, offset: const Offset(0, 4)),
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: GoogleFonts.fredoka(
              fontSize: 13.sp, fontWeight: FontWeight.bold,
              color: isFocused ? appColors.accentBlue : colorScheme.onSurfaceVariant,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 5),
              child: Text(label),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: isFocused
                  ? LinearGradient(colors: [appColors.accentBlue, appColors.accentPurple])
                  : LinearGradient(colors: [
                      appColors.goalCardUnselectedBorder,
                      appColors.accentPurple.withValues(alpha: 0.35),
                    ]),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(11),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: isPassword && !_isPasswordVisible,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                style: GoogleFonts.fredoka(
                  color: colorScheme.onSurface, fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.fredoka(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55), fontSize: 14.sp,
                  ),
                  prefixIcon: Icon(
                    isPassword ? Icons.lock_outline_rounded : Icons.edit_outlined,
                    color: isFocused ? appColors.accentBlue : colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasText)
                        AnimatedScale(
                          scale: 1.0, duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 22.w, height: 22.h,
                              decoration: BoxDecoration(
                                  color: appColors.accentBlue, shape: BoxShape.circle),
                              child: Icon(Icons.check, color: appColors.overlayOnGradient, size: 13),
                            ),
                          ),
                        ),
                      if (isPassword)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                key: ValueKey(_isPasswordVisible),
                                color: isFocused ? appColors.accentBlue : colorScheme.onSurfaceVariant,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DROPDOWN ANIMADO ──
  Widget _dropdown(String label, String hint, String? value,
      List<String> items, ValueChanged<String?> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(label,
            style: GoogleFonts.fredoka(
              fontSize: 13.sp, fontWeight: FontWeight.bold,
              color: hasValue ? appColors.accentBlue : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: hasValue
                ? LinearGradient(colors: [appColors.accentBlue, appColors.accentPurple])
                : LinearGradient(colors: [
                    appColors.goalCardUnselectedBorder,
                    appColors.accentPurple.withValues(alpha: 0.35),
                  ]),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(11),
            ),
            child: DropdownButtonHideUnderline(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text(hint, style: GoogleFonts.fredoka(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55), fontSize: 14.sp,
                  )),
                  value: value,
                  icon: hasValue
                      ? Container(
                          width: 22.w, height: 22.h,
                          decoration: BoxDecoration(
                              color: appColors.accentBlue, shape: BoxShape.circle),
                          child: Icon(Icons.check, color: appColors.overlayOnGradient, size: 13),
                        )
                      : Icon(Icons.keyboard_arrow_down_rounded,
                          color: appColors.accentPurple),
                  items: items.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: GoogleFonts.fredoka(
                      color: colorScheme.onSurface, fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    )),
                  )).toList(),
                  onChanged: onChanged,
                  style: GoogleFonts.fredoka(color: colorScheme.onSurface, fontSize: 14.sp),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── DATE PICKER ──
  Widget _datePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final hasDate = _fechaNacimientoController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text('Fecha de nacimiento',
            style: GoogleFonts.fredoka(
              fontSize: 13.sp, fontWeight: FontWeight.bold,
              color: hasDate ? appColors.accentBlue : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(now.year - 18, now.month, now.day),
              firstDate: DateTime(1900), lastDate: now,
            );
            if (picked != null) {
              setState(() => _fechaNacimientoController.text = _formatDate(picked));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: hasDate
                  ? LinearGradient(colors: [appColors.accentBlue, appColors.accentPurple])
                  : LinearGradient(colors: [
                      appColors.goalCardUnselectedBorder,
                      appColors.accentPurple.withValues(alpha: 0.35),
                    ]),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18,
                      color: hasDate ? appColors.accentBlue : colorScheme.onSurfaceVariant),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      hasDate ? _fechaNacimientoController.text : 'Selecciona tu fecha',
                      style: GoogleFonts.fredoka(
                        color: hasDate ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasDate)
                    Container(
                      width: 22.w, height: 22.h,
                      decoration: BoxDecoration(
                          color: appColors.accentBlue, shape: BoxShape.circle),
                      child: Icon(Icons.check, color: appColors.overlayOnGradient, size: 13),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepMeta {
  final String emoji;
  final String title;
  final String subtitle;
  const _StepMeta({required this.emoji, required this.title, required this.subtitle});
}
