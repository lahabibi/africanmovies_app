import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class PurchasedBadge extends StatelessWidget {
  const PurchasedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 3.5.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.heroButton.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.heroButton.withValues(alpha: 0.9),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroButton.withValues(alpha: 0.35),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Text(
        'Purchased',
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}