import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';

const careBlue = Color(0xFF2878C8);
const careTeal = Color(0xFF43C6B9);
const careNavy = Color(0xFF173F72);

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
              color: careBlue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.maybePop(context),
                child: Padding(
                  padding: EdgeInsets.all(9.w),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
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
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [careTeal, careBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: careBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        psychologist.initials,
        style: TextStyle(
          color: Colors.white,
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
                color: careBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: careBlue, size: 42.sp),
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
                  backgroundColor: careBlue,
                  foregroundColor: Colors.white,
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

Color assignmentStatusColor(AssignmentStatus status) {
  switch (status) {
    case AssignmentStatus.pending:
      return const Color(0xFFF2A51A);
    case AssignmentStatus.approved:
      return const Color(0xFF219653);
    case AssignmentStatus.rejected:
      return const Color(0xFFD64545);
    case AssignmentStatus.finished:
      return const Color(0xFF667085);
    case AssignmentStatus.unknown:
      return const Color(0xFF667085);
  }
}
