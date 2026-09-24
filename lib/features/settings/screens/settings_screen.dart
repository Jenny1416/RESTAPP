import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../home/screens/gradient_text.dart';
import 'feedback_screen.dart';
import 'profile_screen.dart'; // Importar la pantalla de perfil
import 'change_password_screen.dart';
import 'fail_report_screen.dart'; // Importar la pantalla de reporte de fallas
import 'language_screen.dart';
import 'remote_legal_screen.dart';
import 'behaviour_code_screen.dart';
import 'privacity_screen.dart';
import 'terms_screen.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/services/theme_service.dart';
import 'package:rest/core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        titleSpacing: 0, // Reducido para mejor control del espaciado
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leadingWidth: 70, // Ancho específico para el leading
        leading: Center(
          // Centra verticalmente el botón
          child: Container(
            margin: const EdgeInsets.only(
              left: 20,
            ), // Margen desde la izquierda
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: appColors.brandSoft,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: appColors.overlayOnGradient,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
        title: Container(
          margin: const EdgeInsets.only(
            left: 10,
          ), // Pequeño margen para separar del botón
          child: GradientText(
            'Configuración',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30.sp),
            gradient: LinearGradient(
              colors: [appColors.accentTeal, appColors.accentBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Cuenta', context),
                SizedBox(height: 15.h),
                _buildConfigItem('Perfil', Icons.person_outline, () {
                  // Navegar a la pantalla de perfil
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                }, context),
                _buildConfigItem('Contraseña', Icons.lock_outline, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                }, context),
                _buildConfigItem(
                  'Plan Actual',
                  Icons.diamond_outlined,
                  () {},
                  context,
                  disabled: true,
                ),
                _buildConfigItem(
                  'Referidos',
                  Icons.group_outlined,
                  () {},
                  context,
                  disabled: true,
                ),
                _buildConfigItem(
                  'Código de regalo',
                  Icons.card_giftcard_outlined,
                  () {},
                  context,
                  disabled: true,
                ),

                SizedBox(height: 30.h),
                _buildSectionTitle('Ajustes', context),
                SizedBox(height: 15.h),
                _buildDarkModeItem(context),
                _buildConfigItem(
                  'Recordatorios',
                  Icons.notifications_outlined,
                  () {},
                  context,
                  disabled: true,
                ),
                _buildConfigItem(
                  'Pin de seguridad',
                  Icons.lock_outlined,
                  () {},
                  context,
                  disabled: true,
                ),
                _buildConfigItem('Idioma', Icons.language_outlined, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LanguageScreen()),
                  );
                }, context),

                SizedBox(height: 30.h),
                _buildSectionTitle('Soporte', context),
                SizedBox(height: 15.h),
                _buildConfigItem(
                  'Reportar falla técnica',
                  Icons.bug_report_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FailReportScreen(),
                      ),
                    );
                  },
                  context,
                ),
                _buildConfigItem(
                  'Enviar feedback',
                  Icons.feedback_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackScreen()),
                    );
                  },
                  context,
                ),
                _buildConfigItem(
                  'Código de conducta',
                  Icons.gavel_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RemoteLegalScreen(
                          title: 'Código de conducta',
                          path: '/api/settings/code-of-conduct',
                          fallbackBuilder: (_) => BehaviourCodeScreen(),
                        ),
                      ),
                    );
                  },
                  context,
                ),
                _buildConfigItem(
                  'Aviso de privacidad',
                  Icons.privacy_tip_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RemoteLegalScreen(
                          title: 'Aviso de privacidad',
                          path: '/api/settings/privacy-policy',
                          fallbackBuilder: (_) => PrivacityScreen(),
                        ),
                      ),
                    );
                  },
                  context,
                ),
                _buildConfigItem(
                  'Términos y condiciones',
                  Icons.description_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RemoteLegalScreen(
                          title: 'Términos y condiciones',
                          path: '/api/settings/terms',
                          fallbackBuilder: (_) => TermsScreen(),
                        ),
                      ),
                    );
                  },
                  context,
                ),

                SizedBox(height: 40.h),
                Container(
                  width: double.infinity,
                  height: 55.h,
                  decoration: BoxDecoration(
                    color: appColors.dangerFg,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: appColors.dangerFg.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                      child: Center(
                        child: Text(
                          'CERRAR SESIÓN',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: appColors.overlayOnGradient,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDarkModeItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: context.appColors.brandBorder.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode_outlined,
                    color: context.appColors.brandBorder,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Modo oscuro',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isDark,
                    onChanged: (value) =>
                        ThemeService.instance.setDarkMode(value),
                    activeThumbColor: context.appColors.brandBorder,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigItem(
    String title,
    IconData icon,
    VoidCallback onTap,
    BuildContext context, {
    bool disabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = disabled
        ? colorScheme.onSurface.withValues(alpha: 0.35)
        : context.appColors.brandBorder;
    final textColor = disabled
        ? colorScheme.onSurface.withValues(alpha: 0.35)
        : colorScheme.onSurface;
    final bgColor = disabled
        ? colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
        : colorScheme.surface;
    final borderColor = disabled
        ? colorScheme.outlineVariant.withValues(alpha: 0.35)
        : colorScheme.outlineVariant.withValues(alpha: 0.8);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (disabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Próximamente',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Limpiar datos de sesión en memoria y storage
                await UserSession.clear();

                // Navegar a la pantalla de login y limpiar el stack
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
              child: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: context.appColors.dangerFg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
