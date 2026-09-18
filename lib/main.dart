import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/routes/app_routes.dart';
import 'core/services/theme_service.dart';
import 'core/services/user_session.dart';
import 'core/theme/app_theme.dart';
import 'features/intro_auth/screens/how_you_found_screen.dart';
import 'features/intro_auth/screens/intro_screen.dart';
import 'features/intro_auth/screens/login_screen.dart';
import 'features/intro_auth/screens/register_screen.dart';
import 'features/intro_auth/screens/forgot_password_screen.dart';
import 'features/help/screens/cancelhelp_screen.dart';
import 'features/help/screens/help_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/emotion/screens/emotionregister_screen.dart';
import 'features/emotion/screens/chat_screen.dart';
import 'features/emotion/screens/traffic_light_screen.dart';
import 'features/emotion/screens/advice_screen.dart';
import 'features/emotion/screens/check_screen.dart';
import 'features/navigation/main_app.dart';
import 'features/progress/screens/globalprogress_screen.dart';
import 'features/progress/screens/myprogress_screen.dart';
import 'features/progress/screens/mi_diario_screen.dart';
import 'features/progress/screens/mis_capitulos_screen.dart';
import 'features/progress/screens/capitulo_detalle_screen.dart';
import 'features/progress/screens/my_relaxation_techniques.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.loadThemeMode();
  await UserSession.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.instance.themeModeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              initialRoute: AppRoutes.intro,
              routes: {
                // Intro & Auth
                AppRoutes.intro: (context) => IntroScreen(),
                AppRoutes.login: (context) => LoginScreen(),
                AppRoutes.register: (context) => RegisterScreen(),
                AppRoutes.forgotPassword: (context) =>
                    const ForgotPasswordScreen(),
                AppRoutes.howYouFound: (context) => HowYouFoundScreen(),

                // Main App
                AppRoutes.mainApp: (context) => MainApp(),

                // Home
                AppRoutes.home: (context) => HomeScreen(),
                AppRoutes.settings: (context) => SettingsScreen(),

                // Ayuda
                AppRoutes.help: (context) => HelpScreen(),
                AppRoutes.cancelhelp: (context) => CancelHelpScreen(),

                // Registro Emocional
                AppRoutes.emotionHome: (context) => EmotionRegisterScreen(),
                AppRoutes.chat: (context) => ChatScreen(),
                AppRoutes.trafficLight: (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  return TrafficLightScreen(
                    estado: args?["estado"] ?? "excelente",
                    mensaje: args?["mensaje"] ?? "¡Qué bien te sientes hoy!",
                    botonTexto: args?["botonTexto"] ?? "Continuar",
                    promedioHoy: (args?["promedio"] is num)
                        ? (args!["promedio"] as num).toDouble()
                        : null,
                  );
                },

                AppRoutes.advice: (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  return AdviceScreen(
                    userName: args?["userName"] ?? "Usuario",
                    adviceTitle: args?["adviceTitle"] ?? "Consejo",
                    message: args?["message"] ?? "consejo personalizado.",
                    promedioHoy: (args?["promedioHoy"] is num)
                        ? (args!["promedioHoy"] as num).toDouble()
                        : null,
                    estado: args?["estado"] ?? "normal",
                  );
                },
                AppRoutes.check: (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  final promedioHoy = (args?["promedioHoy"] is num)
                      ? (args!["promedioHoy"] as num).toDouble()
                      : null;
                  return CheckScreen(promedioHoy: promedioHoy);
                },

                // Mi Progreso
                AppRoutes.globalprogress: (context) => GlobalProgressScreen(),
                AppRoutes.progress: (context) => MyProgressScreen(),
                AppRoutes.miDiario: (context) => const MisCapitulosScreen(),
                AppRoutes.misCapitulos: (context) => const MisCapitulosScreen(),
                AppRoutes.misTecnicas: (context) => const MisTecnicasScreen(),

                AppRoutes.capituloDetalle: (context) {
                  final args =
                      ModalRoute.of(context)!.settings.arguments
                          as Map<String, dynamic>?;
                  return CapituloDetalleScreen(
                    titulo: args?['titulo'],
                    descripcion: args?['descripcion'],
                    fecha: args?['fecha'],
                  );
                },
              },
            );
          },
        );
      },
    );
  }
}
