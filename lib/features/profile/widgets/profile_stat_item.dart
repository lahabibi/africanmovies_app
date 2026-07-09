import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class ProfileStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const ProfileStatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompactPhone = size.shortestSide < 600 && size.height <= 700;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.heroButton,
              size: isCompactPhone ? 22.sp : 26.sp,
            ),
            SizedBox(width: isCompactPhone ? 8.w : 12.w),
            Text(
              value,
              style: TextStyle(
                fontSize: isCompactPhone ? 21.sp : 24.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompactPhone ? 7.h : 10.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompactPhone ? 11.5.sp : 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
