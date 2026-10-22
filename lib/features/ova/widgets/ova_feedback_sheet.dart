import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';

/// Valoración que el estudiante da al terminar una actividad.
typedef OvaFeedback = ({bool liked, int? rating});

Future<OvaFeedback?> showOvaFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<OvaFeedback>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const _OvaFeedbackSheet(),
  );
}

class _OvaFeedbackSheet extends StatefulWidget {
  const _OvaFeedbackSheet();

  @override
  State<_OvaFeedbackSheet> createState() => _OvaFeedbackSheetState();
}

class _OvaFeedbackSheetState extends State<_OvaFeedbackSheet> {
  bool? _liked;
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Buen trabajo!',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w800,
                fontSize: 22.sp,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '¿Qué te pareció la actividad?',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14.sp,
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    icon: Icons.thumb_up_alt_outlined,
                    label: 'Me gustó',
                    selected: _liked == true,
                    color: appColors.successFg,
                    onTap: () => setState(() => _liked = true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _ChoiceButton(
                    icon: Icons.thumb_down_alt_outlined,
                    label: 'No me gustó',
                    selected: _liked == false,
                    color: appColors.dangerFg,
                    onTap: () => setState(() => _liked = false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Text(
              'Califícala (opcional)',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: List.generate(5, (index) {
                final value = index + 1;
                final active = value <= _rating;
                return IconButton(
                  tooltip: '$value de 5',
                  onPressed: () =>
                      setState(() => _rating = _rating == value ? 0 : value),
                  icon: Icon(
                    active ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 34.sp,
                    color: active ? appColors.warmBadgeFg : colors.outline,
                  ),
                );
              }),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _liked == null
                    ? null
                    : () => Navigator.pop<OvaFeedback>(context, (
                        liked: _liked!,
                        rating: _rating == 0 ? null : _rating,
                      )),
                style: FilledButton.styleFrom(
                  backgroundColor: appColors.accentBlue,
                  foregroundColor: appColors.overlayOnGradient,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  textStyle: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Enviar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? color.withValues(alpha: 0.14)
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected ? color : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : colors.onSurfaceVariant),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: selected ? color : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
