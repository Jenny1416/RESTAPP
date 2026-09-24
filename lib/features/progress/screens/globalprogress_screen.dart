import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';

class GlobalProgressScreen extends StatelessWidget {
  const GlobalProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> agostoDays = [
      {"day": 1, "emoji": "assets/images/smilerest.jpg"},
      {"day": 2, "emoji": "assets/images/sadrest.jpg"},
      {"day": 3, "emoji": "assets/images/smilerest.jpg"},
      {"day": 4, "emoji": "assets/images/sadrest.jpg"},
      {"day": 5, "emoji": "assets/images/normalrest.jpg"},
      {"day": 6, "emoji": "assets/images/goodrest.jpg"},
      {"day": 7, "emoji": "assets/images/normalrest.jpg"},
      {"day": 8, "emoji": "assets/images/sadrest.jpg"},
      {"day": 9, "emoji": "assets/images/goodrest.jpg"},
      {"day": 10, "emoji": "assets/images/sadrest.jpg"},
      {"day": 11, "emoji": "assets/images/goodrest.jpg"},
    ];

    final List<Map<String, dynamic>> septiembreDays = [
      {"day": 1, "emoji": "assets/images/smilerest.jpg"},
      {"day": 2, "emoji": "assets/images/normalrest.jpg"},
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cerrar y título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.primary,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    "Registro Global",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 40.w), // para balancear
                ],
              ),
              SizedBox(height: 20.h),

              // Switch Mes/Año
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [appColors.accentTeal, appColors.accentBlue],
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSwitchButton(context, "Mes", true),
                    _buildSwitchButton(context, "Año", false),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              // Agosto
              _buildMonthSection(context, "Agosto", 31, agostoDays, startOffset: 5),
              SizedBox(height: 30.h),

              // Septiembre
              _buildMonthSection(context, "Septiembre", 30, septiembreDays, startOffset: 0),
            ],
          ),
        ),
      ),
    );
  }

  // Botón del switch Mes/Año
  Widget _buildSwitchButton(BuildContext context, String text, bool active) {
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: active ? appColors.chipAvatarBg : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: active ? colorScheme.primary : appColors.overlayOnGradient,
        ),
      ),
    );
  }

  // Sección de un mes
  Widget _buildMonthSection(
    BuildContext context,
    String month,
    int totalDays,
    List<Map<String, dynamic>> emojiDays, {
    int startOffset = 0,
  }) {
    return Column(
      children: [
        Text(
          month,
          style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10.h),

        // Encabezado de semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: Text("LUN", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),)),
            Expanded(child: Text("MAR", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),)),
            Expanded(child: Text("MIE", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),)),
            Expanded(child: Text("JUE", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),)),
            Expanded(child: Text("VIE", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),)),
            Expanded(child: Text("SAB", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),)),
            Expanded(child: Text("DOM", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.sp),)),
          ],
        ),
        SizedBox(height: 10.h),

        // Calendario
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 filas x 7 columnas
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              int dayNumber = index - startOffset + 1;
              if (dayNumber <= 0 || dayNumber > totalDays) {
                return Container(); // vacío
              }

              // busca si este día tiene emoji
              Map<String, dynamic>? emojiDay;
              try {
                emojiDay = emojiDays.firstWhere(
                  (e) => e["day"] == dayNumber,
                );
              } catch (e) {
                emojiDay = null;
              }

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Text(
                        "$dayNumber",
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                    if (emojiDay != null)
                      Center(
                        child: Image.asset(
                          emojiDay['emoji'],
                          width: 40.w,
                          height: 40.h,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
