import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/expiry_badge.dart';

class LibraryMovieCard extends StatelessWidget {
  final String image;
  final String expiryText;
  final String actionText;
  final String? expiryBadgeText;
  final VoidCallback? onTap;

  const LibraryMovieCard({
    super.key,
    required this.image,
    required this.expiryText,
    required this.actionText,
    this.expiryBadgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108.w, //118
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 158.h, //168
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.cardBorder,
                  width: .8,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                    ),
                  ),

                  if (expiryBadgeText != null)
                    Positioned(
                      top: 6.h,
                      left: 6.w,
                      child: ExpiryBadge(
                        text: expiryBadgeText!,
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),

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
                actionText,
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
    );
  }
}