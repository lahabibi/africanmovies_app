import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class AppContextMenu extends StatelessWidget {
  final Widget child;
  final List<AppContextMenuItem> items;

  const AppContextMenu({
    super.key,
    required this.child,
    required this.items,
  });

  void _showMenu(BuildContext context) {
    final button = context.findRenderObject() as RenderBox;
    final overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: Colors.transparent,
      elevation: 0,
      items: items.map((item) {
        return PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _MenuItem(item: item),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: child,
    );
  }
}

class AppContextMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const AppContextMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
}

class _MenuItem extends StatelessWidget {
  final AppContextMenuItem item;

  const _MenuItem({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        item.onTap?.call();
      },
      child: Container(
        width: 170.w,
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.heroButton.withValues(alpha: .15),
              blurRadius: 20.r,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.heroButton.withValues(alpha: .12),
              ),
              child: Icon(
                item.icon,
                color: AppColors.heroButton,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.heroButton,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}