import 'package:africanmovies/features/profile/devices_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class DeviceCard extends StatelessWidget {
  final DeviceInfo device;
  final VoidCallback? onSignOut;

  const DeviceCard({super.key, required this.device, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(device.icon, color: AppColors.primary, size: 28.sp),
          ),

          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (device.isCurrentDevice) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'This device',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 2.h),

                Text(
                  '${device.location}  •  ${device.os}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (!device.isCurrentDevice && device.lastActive != null) ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Last active: ${device.lastActive}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .62),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 10.w),

          if (device.isCurrentDevice)
            Icon(Icons.check_rounded, color: AppColors.primary, size: 26.sp)
          else
            OutlinedButton(
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: .24)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
              child: Text(
                'Sign out',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
