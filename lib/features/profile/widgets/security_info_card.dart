import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class SecurityInfoCard extends StatelessWidget {
  const SecurityInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: AppColors.primary,
            size: 30.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'If you don’t recognize a device, we recommend signing out of it.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .68),
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Learn more',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}