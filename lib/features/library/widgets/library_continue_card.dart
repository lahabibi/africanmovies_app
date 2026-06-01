import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';

class LibraryContinueCard extends StatelessWidget {
  final String image;
  final double progress;
  final String progressText;
  final String timeLeft;
  final String expiryText;
  final VoidCallback? onTap;

  const LibraryContinueCard({
    super.key,
    required this.image,
    required this.progress,
    required this.progressText,
    required this.timeLeft,
    required this.expiryText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140.w,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.asset(
                        image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Positioned(
                    left: 8.w,
                    bottom: 8.h,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.h,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation(AppColors.heroButton),
              ),
            ),

            SizedBox(height: 6.h),

            Row(
              children: [
                Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  timeLeft,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),

            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: const Color(0xFFFFB000),
                  size: 10.sp,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    expiryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFFFB000),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            SizedBox(
              width: double.infinity,
              height: 24.h,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.play_arrow_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
                label: Text(
                  'Resume',
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF072A52),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  side: BorderSide(
                    color: AppColors.heroButton,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}