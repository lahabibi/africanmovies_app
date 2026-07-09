import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class AuthFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AuthFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompactPhone = size.shortestSide < 600 && size.height <= 700;
    final cardHeight = isCompactPhone ? 150.0 : 142.h;
    final cardPadding = isCompactPhone ? 14.w : 16.w;
    final iconSize = isCompactPhone ? 30.sp : 34.sp;
    final lockSize = isCompactPhone ? 30.w : 32.w;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: cardHeight,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .035),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: AppColors.primary, size: iconSize),
                  Container(
                    width: lockSize,
                    height: lockSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .10),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompactPhone ? 15.5.sp : 17.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: isCompactPhone ? 4.h : 6.h),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .65),
                        fontSize: isCompactPhone ? 11.sp : 12.sp,
                        height: isCompactPhone ? 1.25 : 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
