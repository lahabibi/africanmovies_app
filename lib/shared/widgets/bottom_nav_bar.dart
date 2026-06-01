import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class BottomNavItem {
  final String icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const items = [
    BottomNavItem(icon: AppAssets.home, label: 'Home'),
    BottomNavItem(icon: AppAssets.genre, label: 'Genres'),
    BottomNavItem(icon: AppAssets.watchlist, label: 'Watchlist'),
    BottomNavItem(icon: AppAssets.playlist, label: 'My Library'),
    BottomNavItem(icon: AppAssets.user, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66.h,
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = currentIndex == index;

          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 58.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    item.icon,
                    width: 20.w,
                    height: 20.w,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}