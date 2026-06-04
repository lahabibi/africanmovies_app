import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_device_session.dart';

class DeviceCard extends StatelessWidget {
  final AuthDeviceSession device;
  final VoidCallback? onSignOut;
  final bool isBusy;

  const DeviceCard({
    super.key,
    required this.device,
    this.onSignOut,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final lastActiveLabel = _lastActiveLabel(device.lastActiveAt);

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
            child: Icon(
              _iconFor(device),
              color: AppColors.primary,
              size: 28.sp,
            ),
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
                        device.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (device.isCurrent) ...[
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
                  '${device.locationLabel}  •  ${device.osLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (lastActiveLabel != null) ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Last active: $lastActiveLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

          if (device.isCurrent)
            Icon(Icons.check_rounded, color: AppColors.primary, size: 26.sp)
          else
            OutlinedButton(
              onPressed: isBusy ? null : onSignOut,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: .24)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              ),
              child: isBusy
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
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

  IconData _iconFor(AuthDeviceSession device) {
    final label = '${device.platform} ${device.os} ${device.deviceType}'
        .toLowerCase();

    if (label.contains('android')) return Icons.phone_android_rounded;
    if (label.contains('ios') || label.contains('iphone')) {
      return Icons.phone_iphone_rounded;
    }
    if (label.contains('mac')) return Icons.laptop_mac_rounded;
    if (label.contains('windows')) return Icons.desktop_windows_rounded;
    if (label.contains('linux')) return Icons.computer_rounded;
    if (label.contains('mobile')) return Icons.phone_iphone_rounded;

    return Icons.devices_rounded;
  }

  String? _lastActiveLabel(DateTime? value) {
    if (value == null) return null;

    final now = DateTime.now();
    final localValue = value.toLocal();
    final difference = now.difference(localValue);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[localValue.month - 1]} ${localValue.day}, '
        '${localValue.year}';
  }
}
