import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_image.dart';

class GenreMovieGridCard extends StatelessWidget {
  final String image;
  final String year;
  final String duration;
  final String ageRating;
  final VoidCallback? onTap;

  const GenreMovieGridCard({
    super.key,
    required this.image,
    required this.year,
    required this.duration,
    required this.ageRating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: AppImage(source: image)),

            Positioned(
              left: 6.w,
              right: 6.w,
              bottom: 6.h,
              child: Row(
                children: [
                  Flexible(child: _MetaBadge(text: year)),
                  SizedBox(width: 4.w),
                  Flexible(flex: 2, child: _MetaBadge(text: duration)),
                  SizedBox(width: 4.w),
                  Flexible(child: _MetaBadge(text: ageRating)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String text;

  const _MetaBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
