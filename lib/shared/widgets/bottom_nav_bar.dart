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
    final isCompactPhone =
        !isTablet && MediaQuery.sizeOf(context).height <= 700;
    final horizontalMargin = isTablet ? 24.0 : (isCompactPhone ? 14.w : 20.w);
    final bottomMargin = isTablet ? 24.0 : (isCompactPhone ? 12.h : 24.h);
    final navHeight = isTablet ? 70.0 : (isCompactPhone ? 60.h : 66.h);
    final verticalPadding = isTablet ? 10.0 : (isCompactPhone ? 7.h : 10.h);
    final iconSize = isTablet ? 22.0 : (isCompactPhone ? 18.w : 20.w);
    final labelGap = isTablet ? 5.0 : (isCompactPhone ? 3.h : 5.h);
    final labelFontSize = isTablet ? 11.0 : (isCompactPhone ? 9.2.sp : 10.sp);
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
                vertical: verticalPadding,
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
                            width: iconSize,
                            height: iconSize,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(height: labelGap),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: labelFontSize,
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
