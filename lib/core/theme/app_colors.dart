import 'package:flutter/material.dart';

/// Tokens semánticos de color usados en toda la app (RestApp).
///
/// Cada pantalla que antes usaba `Color(0xFF...)` o `Colors.white` de forma
/// fija ahora debe resolver el color contra `context.appColors.<token>`,
/// que cambia automáticamente entre [AppColors.light] y [AppColors.dark]
/// según el `ThemeMode` activo (ver `ThemeService` y `AppTheme`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.infoBadgeBg,
    required this.infoBadgeFg,
    required this.warmBadgeBg,
    required this.warmBadgeFg,
    required this.warmSurfaceBg,
    required this.warmSurfaceBorder,
    required this.warmSurfaceFg,
    required this.progressTrackCool,
    required this.progressFillCool,
    required this.progressTrackWarm,
    required this.progressFillWarm,
    required this.heroGradientCoolStart,
    required this.heroGradientCoolEnd,
    required this.heroGradientLavenderStart,
    required this.heroGradientLavenderEnd,
    required this.navGradientStart,
    required this.navGradientEnd,
    required this.chipAvatarBg,
    required this.reminderCardBg,
    required this.reminderCardFg,
    required this.reminderCardBorder,
    required this.brandBorder,
    required this.cardBorderTeal,
    required this.successBg,
    required this.successFg,
    required this.dangerBg,
    required this.dangerFg,
    required this.neutralMutedText,
    required this.overlayOnGradient,
    required this.goalCardUnselectedBg,
    required this.goalCardUnselectedBorder,
    required this.goalCardUnselectedText,
    required this.accentBlue,
    required this.accentPurple,
    required this.accentTeal,
    required this.brandSoft,
    required this.goldStart,
    required this.goldEnd,
  });

  /// Badge/botón informativo azul claro (ej. "Progreso de hoy", botón Premios).
  final Color infoBadgeBg;
  final Color infoBadgeFg;

  /// Badge cálido pequeño (ej. contador de estrellas de hoy, precio de premio).
  final Color warmBadgeBg;
  final Color warmBadgeFg;

  /// Superficie cálida más grande (ej. tarjeta "Estrellas del mes").
  final Color warmSurfaceBg;
  final Color warmSurfaceBorder;
  final Color warmSurfaceFg;

  /// Barra de progreso "fría" (ej. progreso diario de actividades).
  final Color progressTrackCool;
  final Color progressFillCool;

  /// Barra de progreso "cálida" (ej. estrellas del mes).
  final Color progressTrackWarm;
  final Color progressFillWarm;

  /// Gradiente hero frío (ej. tarjeta Registro Emocional).
  final Color heroGradientCoolStart;
  final Color heroGradientCoolEnd;

  /// Gradiente hero lavanda (ej. tarjeta de racha).
  final Color heroGradientLavenderStart;
  final Color heroGradientLavenderEnd;

  /// Gradiente de la barra de navegación inferior.
  final Color navGradientStart;
  final Color navGradientEnd;

  /// Fondo de avatares/chips circulares pequeños (ej. emoji del día).
  final Color chipAvatarBg;

  /// Tarjeta recordatorio de onboarding.
  final Color reminderCardBg;
  final Color reminderCardFg;
  final Color reminderCardBorder;

  /// Borde de marca usado en tarjetas con contorno (InfoCard, etc.).
  final Color brandBorder;

  /// Borde teal claro usado en tarjetas del dashboard (Mi diario, técnicas,
  /// actividades diarias).
  final Color cardBorderTeal;

  /// Estados de éxito / error genéricos.
  final Color successBg;
  final Color successFg;
  final Color dangerBg;
  final Color dangerFg;

  /// Texto secundario neutro (equivalente semántico de 0xFF6B7280).
  final Color neutralMutedText;

  /// Color de texto/iconos que va sobre gradientes de marca saturados
  /// (se mantiene blanco en ambos modos porque el gradiente ya es oscuro).
  final Color overlayOnGradient;

  /// Tarjeta de meta no seleccionada (GoalPickerScreen).
  final Color goalCardUnselectedBg;
  final Color goalCardUnselectedBorder;
  final Color goalCardUnselectedText;

  /// Acentos saturados de racha / CTAs (azul, violeta, teal).
  final Color accentBlue;
  final Color accentPurple;
  final Color accentTeal;

  /// Azul cielo de avatares y botones circulares de cabecera (0xFF87CEEB).
  final Color brandSoft;

  /// Gradiente dorado (reclamar estrella diaria).
  final Color goldStart;
  final Color goldEnd;

  static const AppColors light = AppColors(
    infoBadgeBg: Color(0xFFE8F7FF),
    infoBadgeFg: Color(0xFF1565C0),
    warmBadgeBg: Color(0xFFFFF3E0),
    warmBadgeFg: Color(0xFFBF6D00),
    warmSurfaceBg: Color(0xFFFFFAEE),
    warmSurfaceBorder: Color(0xFFFFE1A8),
    warmSurfaceFg: Color(0xFF8A5200),
    progressTrackCool: Color(0xFFCFEDFA),
    progressFillCool: Color(0xFF26A69A),
    progressTrackWarm: Color(0xFFFFEFD1),
    progressFillWarm: Color(0xFFFFB300),
    heroGradientCoolStart: Color(0xFF7DD3E8),
    heroGradientCoolEnd: Color(0xFF9FE6FF),
    heroGradientLavenderStart: Color(0xFFF0F4FF),
    heroGradientLavenderEnd: Color(0xFFF5F0FF),
    navGradientStart: Color(0xFF4DB6AC),
    navGradientEnd: Color(0xFF3F51B5),
    chipAvatarBg: Colors.white,
    reminderCardBg: Color(0xFFFFF4DD),
    reminderCardFg: Color(0xFF7A5B00),
    reminderCardBorder: Color(0xFFFFE1A8),
    brandBorder: Color(0xFF2F9FE8),
    cardBorderTeal: Color(0xFF7DD3E8),
    successBg: Color(0xFFE6F4EA),
    successFg: Color(0xFF2E7D32),
    dangerBg: Color(0xFFFDECEA),
    dangerFg: Color(0xFFC62828),
    neutralMutedText: Color(0xFF6B7280),
    overlayOnGradient: Colors.white,
    goalCardUnselectedBg: Color(0xFFF3F4FF),
    goalCardUnselectedBorder: Color(0xFFCDD8FF),
    goalCardUnselectedText: Color(0xFF1A1A2E),
    accentBlue: Color(0xFF3A5AFF),
    accentPurple: Color(0xFF8C4EFF),
    accentTeal: Color(0xFF5CCFC0),
    brandSoft: Color(0xFF87CEEB),
    goldStart: Color(0xFFFFD54F),
    goldEnd: Color(0xFFFFA000),
  );

  static const AppColors dark = AppColors(
    infoBadgeBg: Color(0xFF16324A),
    infoBadgeFg: Color(0xFF8ECBFF),
    warmBadgeBg: Color(0xFF4A3011),
    warmBadgeFg: Color(0xFFFFC46B),
    warmSurfaceBg: Color(0xFF3A2C12),
    warmSurfaceBorder: Color(0xFF6B4B1E),
    warmSurfaceFg: Color(0xFFFFD08A),
    progressTrackCool: Color(0xFF1D3B3D),
    progressFillCool: Color(0xFF4FD1C5),
    progressTrackWarm: Color(0xFF4A3B14),
    progressFillWarm: Color(0xFFFFC24B),
    heroGradientCoolStart: Color(0xFF123B4D),
    heroGradientCoolEnd: Color(0xFF17506B),
    heroGradientLavenderStart: Color(0xFF23263B),
    heroGradientLavenderEnd: Color(0xFF2B2740),
    navGradientStart: Color(0xFF2E5F58),
    navGradientEnd: Color(0xFF262C57),
    chipAvatarBg: Color(0xFF2A2E45),
    reminderCardBg: Color(0xFF433A1E),
    reminderCardFg: Color(0xFFFFE29A),
    reminderCardBorder: Color(0xFF6B4B1E),
    brandBorder: Color(0xFF5CB2ED),
    cardBorderTeal: Color(0xFF3F8FA0),
    successBg: Color(0xFF1E3D26),
    successFg: Color(0xFF7FD996),
    dangerBg: Color(0xFF3D1F1E),
    dangerFg: Color(0xFFFF8A80),
    neutralMutedText: Color(0xFFAAB0C0),
    overlayOnGradient: Colors.white,
    goalCardUnselectedBg: Color(0xFF23263B),
    goalCardUnselectedBorder: Color(0xFF3A3F63),
    goalCardUnselectedText: Color(0xFFE7E9F5),
    accentBlue: Color(0xFF8BA4FF),
    accentPurple: Color(0xFFC4A0FF),
    accentTeal: Color(0xFF4FD1C5),
    brandSoft: Color(0xFF3A7A96),
    goldStart: Color(0xFFC9A227),
    goldEnd: Color(0xFFB7791F),
  );

  @override
  AppColors copyWith({
    Color? infoBadgeBg,
    Color? infoBadgeFg,
    Color? warmBadgeBg,
    Color? warmBadgeFg,
    Color? warmSurfaceBg,
    Color? warmSurfaceBorder,
    Color? warmSurfaceFg,
    Color? progressTrackCool,
    Color? progressFillCool,
    Color? progressTrackWarm,
    Color? progressFillWarm,
    Color? heroGradientCoolStart,
    Color? heroGradientCoolEnd,
    Color? heroGradientLavenderStart,
    Color? heroGradientLavenderEnd,
    Color? navGradientStart,
    Color? navGradientEnd,
    Color? chipAvatarBg,
    Color? reminderCardBg,
    Color? reminderCardFg,
    Color? reminderCardBorder,
    Color? brandBorder,
    Color? cardBorderTeal,
    Color? successBg,
    Color? successFg,
    Color? dangerBg,
    Color? dangerFg,
    Color? neutralMutedText,
    Color? overlayOnGradient,
    Color? goalCardUnselectedBg,
    Color? goalCardUnselectedBorder,
    Color? goalCardUnselectedText,
    Color? accentBlue,
    Color? accentPurple,
    Color? accentTeal,
    Color? brandSoft,
    Color? goldStart,
    Color? goldEnd,
  }) {
    return AppColors(
      infoBadgeBg: infoBadgeBg ?? this.infoBadgeBg,
      infoBadgeFg: infoBadgeFg ?? this.infoBadgeFg,
      warmBadgeBg: warmBadgeBg ?? this.warmBadgeBg,
      warmBadgeFg: warmBadgeFg ?? this.warmBadgeFg,
      warmSurfaceBg: warmSurfaceBg ?? this.warmSurfaceBg,
      warmSurfaceBorder: warmSurfaceBorder ?? this.warmSurfaceBorder,
      warmSurfaceFg: warmSurfaceFg ?? this.warmSurfaceFg,
      progressTrackCool: progressTrackCool ?? this.progressTrackCool,
      progressFillCool: progressFillCool ?? this.progressFillCool,
      progressTrackWarm: progressTrackWarm ?? this.progressTrackWarm,
      progressFillWarm: progressFillWarm ?? this.progressFillWarm,
      heroGradientCoolStart:
          heroGradientCoolStart ?? this.heroGradientCoolStart,
      heroGradientCoolEnd: heroGradientCoolEnd ?? this.heroGradientCoolEnd,
      heroGradientLavenderStart:
          heroGradientLavenderStart ?? this.heroGradientLavenderStart,
      heroGradientLavenderEnd:
          heroGradientLavenderEnd ?? this.heroGradientLavenderEnd,
      navGradientStart: navGradientStart ?? this.navGradientStart,
      navGradientEnd: navGradientEnd ?? this.navGradientEnd,
      chipAvatarBg: chipAvatarBg ?? this.chipAvatarBg,
      reminderCardBg: reminderCardBg ?? this.reminderCardBg,
      reminderCardFg: reminderCardFg ?? this.reminderCardFg,
      reminderCardBorder: reminderCardBorder ?? this.reminderCardBorder,
      brandBorder: brandBorder ?? this.brandBorder,
      cardBorderTeal: cardBorderTeal ?? this.cardBorderTeal,
      successBg: successBg ?? this.successBg,
      successFg: successFg ?? this.successFg,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerFg: dangerFg ?? this.dangerFg,
      neutralMutedText: neutralMutedText ?? this.neutralMutedText,
      overlayOnGradient: overlayOnGradient ?? this.overlayOnGradient,
      goalCardUnselectedBg: goalCardUnselectedBg ?? this.goalCardUnselectedBg,
      goalCardUnselectedBorder:
          goalCardUnselectedBorder ?? this.goalCardUnselectedBorder,
      goalCardUnselectedText:
          goalCardUnselectedText ?? this.goalCardUnselectedText,
      accentBlue: accentBlue ?? this.accentBlue,
      accentPurple: accentPurple ?? this.accentPurple,
      accentTeal: accentTeal ?? this.accentTeal,
      brandSoft: brandSoft ?? this.brandSoft,
      goldStart: goldStart ?? this.goldStart,
      goldEnd: goldEnd ?? this.goldEnd,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      infoBadgeBg: Color.lerp(infoBadgeBg, other.infoBadgeBg, t)!,
      infoBadgeFg: Color.lerp(infoBadgeFg, other.infoBadgeFg, t)!,
      warmBadgeBg: Color.lerp(warmBadgeBg, other.warmBadgeBg, t)!,
      warmBadgeFg: Color.lerp(warmBadgeFg, other.warmBadgeFg, t)!,
      warmSurfaceBg: Color.lerp(warmSurfaceBg, other.warmSurfaceBg, t)!,
      warmSurfaceBorder:
          Color.lerp(warmSurfaceBorder, other.warmSurfaceBorder, t)!,
      warmSurfaceFg: Color.lerp(warmSurfaceFg, other.warmSurfaceFg, t)!,
      progressTrackCool:
          Color.lerp(progressTrackCool, other.progressTrackCool, t)!,
      progressFillCool:
          Color.lerp(progressFillCool, other.progressFillCool, t)!,
      progressTrackWarm:
          Color.lerp(progressTrackWarm, other.progressTrackWarm, t)!,
      progressFillWarm:
          Color.lerp(progressFillWarm, other.progressFillWarm, t)!,
      heroGradientCoolStart: Color.lerp(
        heroGradientCoolStart,
        other.heroGradientCoolStart,
        t,
      )!,
      heroGradientCoolEnd: Color.lerp(
        heroGradientCoolEnd,
        other.heroGradientCoolEnd,
        t,
      )!,
      heroGradientLavenderStart: Color.lerp(
        heroGradientLavenderStart,
        other.heroGradientLavenderStart,
        t,
      )!,
      heroGradientLavenderEnd: Color.lerp(
        heroGradientLavenderEnd,
        other.heroGradientLavenderEnd,
        t,
      )!,
      navGradientStart: Color.lerp(navGradientStart, other.navGradientStart, t)!,
      navGradientEnd: Color.lerp(navGradientEnd, other.navGradientEnd, t)!,
      chipAvatarBg: Color.lerp(chipAvatarBg, other.chipAvatarBg, t)!,
      reminderCardBg: Color.lerp(reminderCardBg, other.reminderCardBg, t)!,
      reminderCardFg: Color.lerp(reminderCardFg, other.reminderCardFg, t)!,
      reminderCardBorder:
          Color.lerp(reminderCardBorder, other.reminderCardBorder, t)!,
      brandBorder: Color.lerp(brandBorder, other.brandBorder, t)!,
      cardBorderTeal: Color.lerp(cardBorderTeal, other.cardBorderTeal, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      dangerFg: Color.lerp(dangerFg, other.dangerFg, t)!,
      neutralMutedText:
          Color.lerp(neutralMutedText, other.neutralMutedText, t)!,
      overlayOnGradient:
          Color.lerp(overlayOnGradient, other.overlayOnGradient, t)!,
      goalCardUnselectedBg: Color.lerp(
        goalCardUnselectedBg,
        other.goalCardUnselectedBg,
        t,
      )!,
      goalCardUnselectedBorder: Color.lerp(
        goalCardUnselectedBorder,
        other.goalCardUnselectedBorder,
        t,
      )!,
      goalCardUnselectedText: Color.lerp(
        goalCardUnselectedText,
        other.goalCardUnselectedText,
        t,
      )!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      goldStart: Color.lerp(goldStart, other.goldStart, t)!,
      goldEnd: Color.lerp(goldEnd, other.goldEnd, t)!,
    );
  }
}

/// Acceso rápido: `context.appColors.warmSurfaceBg`.
extension AppColorsX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
