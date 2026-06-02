import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';

class BottomNavItem {
  final String icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
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
    final isTablet = Responsive.isTablet(context);
    final horizontalMargin = isTablet ? 24.0 : 20.w;
    final bottomMargin = isTablet ? 24.0 : 24.h;
    final navHeight = isTablet ? 70.0 : 66.h;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final availableWidth =
        MediaQuery.sizeOf(context).width - (horizontalMargin * 2);
    final navWidth = isTablet
        ? math.min(availableWidth, Responsive.bottomNavMaxWidth(context))
        : availableWidth;

    return SizedBox(
      height: navHeight + bottomMargin + bottomInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalMargin,
          0,
          horizontalMargin,
          bottomMargin + bottomInset,
        ),
        child: Center(
          child: SizedBox(
            width: navWidth,
            height: navHeight,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 14 : 12.w,
                vertical: isTablet ? 10 : 10.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            item.icon,
                            width: isTablet ? 22 : 20.w,
                            height: isTablet ? 22 : 20.w,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(height: isTablet ? 5 : 5.h),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isTablet ? 11 : 10.sp,
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
            ),
          ),
        ),
      ),
    );
  }
}
