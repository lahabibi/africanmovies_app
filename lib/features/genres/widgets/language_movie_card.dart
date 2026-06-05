import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_image.dart';

class LanguageMovieCard extends StatelessWidget {
  final String image;
  final String year;
  final String genre;
  final String ageRating;
  final VoidCallback? onTap;

  const LanguageMovieCard({
    super.key,
    required this.image,
    required this.year,
    required this.genre,
    required this.ageRating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 132.h,
              width: 96.w,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: AppImage(source: image),
            ),

            SizedBox(height: 6.h),

            Padding(
              padding: EdgeInsets.only(left: 4.w, right: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$year • $genre',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 0.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      ageRating,
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
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
