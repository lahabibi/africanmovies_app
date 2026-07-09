import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';

class MoviePurchaseButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback? onTap;

  const MoviePurchaseButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isLoading;
    final size = MediaQuery.sizeOf(context);
    final isCompactPhone = size.shortestSide < 600 && size.height <= 700;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: isCompactPhone ? 58 : 58.h,
        padding: EdgeInsets.symmetric(
          horizontal: isCompactPhone ? 12.w : 16.w,
          vertical: isCompactPhone ? 9 : 12.h,
        ),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.deepBlue
              : AppColors.deepBlue.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: isCompactPhone ? 16.sp : 18.sp,
                height: isCompactPhone ? 16.sp : 18.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                icon,
                color: Colors.white,
                size: isCompactPhone ? 17.sp : 18.sp,
              ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLoading ? 'Processing...' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompactPhone ? 10.5.sp : 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: isCompactPhone ? 9.3.sp : 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
