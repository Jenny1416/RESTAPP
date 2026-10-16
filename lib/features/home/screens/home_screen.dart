import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../settings/screens/settings_screen.dart';
import 'activities_screen.dart';
import 'package:rest/features/emotion/screens/chat_screen.dart';
import 'conversations_screen.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/widgets/app_header_bar.dart';
import 'package:rest/features/onboarding/widgets/onboarding_reminder_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScreen();
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeaderBar(
              title: '¡Hola! ${UserSession.displayName}',
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
            Divider(
              color: colorScheme.outlineVariant,
              thickness: 3,
              height: 0.h,
              indent: 23,
              endIndent: 23,
            ),
            SizedBox(height: 20.h),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: const OnboardingReminderCard(),
            ),

            _ChatCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
            ),

            SizedBox(height: 20.h),

            // Botón "ESCOGER UN TEMA"
            SizedBox(height: 40.h),

            // Sección "Mis últimas sesiones"
            Container(
              margin: EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Mis últimas sesiones',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConversacionesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.primary,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Cards de sesiones
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Card Conversaciones
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConversacionesScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Conversaciones',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                                height: 1.2,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                            SizedBox(height: 23.h),
                            Container(
                              width: 90.w,
                              height: 95.h,
                              decoration: BoxDecoration(
                                color: appColors.brandSoft,
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                    'assets/images/conversaciones.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // Card Progreso de las Actividad - CON NAVEGACIÓN
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivitiesScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Progreso de las\nActividades',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                                height: 1.2,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              width: 100.w,
                              height: 90.h,
                              decoration: BoxDecoration(
                                color: appColors.brandSoft,
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                    'assets/images/medalla.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final cardColor = appColors.brandSoft;
    final iconBg = appColors.chipAvatarBg;
    final iconColor = appColors.brandBorder;
    final titleColor = appColors.overlayOnGradient;
    final subtitleColor = appColors.overlayOnGradient.withValues(alpha: 0.7);
    final shadowColor = appColors.brandSoft.withValues(alpha: 0.4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(Icons.forum_rounded, color: iconColor, size: 32),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Quieres hablar\nconmigo?',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Iniciar conversación',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: iconColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
