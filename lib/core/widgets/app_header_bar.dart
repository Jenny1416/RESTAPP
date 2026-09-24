import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'circle_icon_button.dart';

/// Header reutilizable: avatar + titulo + boton circular de accion.
/// Reemplaza el header duplicado que existia en home_screen, myprogress_screen
/// y streak_screen (cada uno con su propio avatar ovalado de tamano fijo).
class AppHeaderBar extends StatelessWidget {
  const AppHeaderBar({
    super.key,
    required this.title,
    required this.onActionTap,
    this.avatarAssetPath = 'assets/images/normalrest.jpg',
    this.actionIcon = Icons.settings,
    this.actionImagePath,
  });

  final String title;
  final VoidCallback onActionTap;
  final String avatarAssetPath;
  final IconData? actionIcon;
  final String? actionImagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: context.appColors.brandSoft,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(avatarAssetPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontFamily: 'Fredoka',
              ),
            ),
          ),
          SizedBox(width: 8.w),
          CircleIconButton(
            onTap: onActionTap,
            icon: actionImagePath == null ? actionIcon : null,
            imagePath: actionImagePath,
          ),
        ],
      ),
    );
  }
}
