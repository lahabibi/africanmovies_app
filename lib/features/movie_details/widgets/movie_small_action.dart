import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';

class MovieSmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isLoading;

  const MovieSmallAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = isActive ? AppColors.heroButton : Colors.white;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 60.w,
        height: 58.h,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.heroButton.withValues(alpha: 0.12)
              : AppColors.card.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isActive
                ? AppColors.heroButton.withValues(alpha: 0.55)
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: contentColor,
                ),
              )
            else
              Icon(icon, color: contentColor, size: 22.sp),
            SizedBox(height: 5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
