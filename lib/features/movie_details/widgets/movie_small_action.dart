import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';

class MovieSmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const MovieSmallAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        height: 58.h,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22.sp),
            SizedBox(height: 5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}