import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';
import '../home/screens/home_screen.dart';
import '../progress/screens/progress_screen.dart';
import '../progress/screens/myprogress_screen.dart';
import '../progress/screens/streak_screen.dart';
import '../professional_care/screens/professional_care_screen.dart';
import 'package:rest/core/services/user_session.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    ProgressScreen(),
    ProfessionalCareScreen(),
    MyProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ProgressScreen.prefetch();
    // Mostrar pantalla de racha después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStreak());
  }

  Future<void> _checkStreak() async {
    await UserSession.load();

    final shouldShow =
        UserSession.showStreakToday || !UserSession.streakGoalSet;
    if (!shouldShow) return;

    // Limpiar flag antes de mostrar para que no vuelva a aparecer
    if (UserSession.showStreakToday) {
      UserSession.showStreakToday = false;
      await UserSession.persist();
    }

    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => const StreakEntryScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// 🌊 Barra personalizada tipo "onda suave"
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      margin: EdgeInsets.all(16.w),
      height: 70.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        gradient: LinearGradient(
          colors: [appColors.navGradientStart, appColors.navGradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildItem(Icons.home, 0, context),
          _buildItem(Icons.pie_chart, 1, context),
          _buildItem(Icons.volunteer_activism_rounded, 2, context),
          _buildItem(Icons.person, 3, context),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, int index, BuildContext context) {
    bool isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: isActive
              ? context.appColors.overlayOnGradient.withValues(alpha: 0.9)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 30.sp,
          color: isActive
              ? context.appColors.infoBadgeFg
              : context.appColors.overlayOnGradient,
        ),
      ),
    );
  }
}
