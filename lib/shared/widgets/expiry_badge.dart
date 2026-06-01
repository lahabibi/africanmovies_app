import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExpiryBadge extends StatelessWidget {
  final String text;

  const ExpiryBadge({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.w,
        vertical: 3.5.h,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD94B43),
            Color(0xFF8E1F1A),
          ],
        ),
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E1F1A).withValues(alpha: 0.42),
            blurRadius: 10,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_filled_rounded,
            color: Colors.white,
            size: 8.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 7.8.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}