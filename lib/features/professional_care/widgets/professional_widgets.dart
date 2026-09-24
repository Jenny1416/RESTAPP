import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';

Color careAccent(BuildContext context) => context.appColors.brandBorder;

class CarePageHeader extends StatelessWidget {
  const CarePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.action,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
      child: Row(
        children: [
          if (showBack) ...[
            Material(
              color: context.appColors.accentBlue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.maybePop(context),
                child: Padding(
                  padding: EdgeInsets.all(9.w),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: context.appColors.overlayOnGradient,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w800,
                    fontSize: 23.sp,
                    color: colors.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class PsychologistAvatar extends StatelessWidget {
  const PsychologistAvatar({
    super.key,
    required this.psychologist,
    this.size = 56,
  });

  final Psychologist psychologist;
  final double size;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.accentTeal, appColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: appColors.accentBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        psychologist.initials,
        style: TextStyle(
          color: appColors.overlayOnGradient,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w800,
          fontSize: (size * 0.34).sp,
        ),
      ),
    );
  }
}

class CareEmptyState extends StatelessWidget {
  const CareEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: appColors.accentBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: appColors.accentBlue, size: 42.sp),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w800,
                fontSize: 21.sp,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14.sp,
                height: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: 20.h),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: appColors.accentBlue,
                  foregroundColor: appColors.overlayOnGradient,
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 14.h,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String assignmentStatusLabel(AssignmentStatus status) {
  switch (status) {
    case AssignmentStatus.pending:
      return 'Pendiente';
    case AssignmentStatus.approved:
      return 'Aprobada';
    case AssignmentStatus.rejected:
      return 'Rechazada';
    case AssignmentStatus.finished:
      return 'Finalizada';
    case AssignmentStatus.unknown:
      return 'Sin estado';
  }
}

Color assignmentStatusColor(BuildContext context, AssignmentStatus status) {
  final appColors = context.appColors;
  switch (status) {
    case AssignmentStatus.pending:
      return appColors.goldEnd;
    case AssignmentStatus.approved:
      return appColors.successFg;
    case AssignmentStatus.rejected:
      return appColors.dangerFg;
    case AssignmentStatus.finished:
      return appColors.neutralMutedText;
    case AssignmentStatus.unknown:
      return appColors.neutralMutedText;
  }
}
