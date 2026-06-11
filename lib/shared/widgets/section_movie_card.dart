import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import 'app_image.dart';

class SectionMovieCard extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final double? borderRadius;
  final bool showFreeBadge;
  final VoidCallback? onTap;

  const SectionMovieCard({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.borderRadius,
    this.showFreeBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 112.w,
        height: height ?? 168.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.sm),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: AppImage(source: image)),
            if (showFreeBadge)
              Positioned(top: 7.h, right: 7.w, child: const _FreeMovieBadge()),
          ],
        ),
      ),
    );
  }
}

class _FreeMovieBadge extends StatelessWidget {
  const _FreeMovieBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.heroButton],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroButton.withValues(alpha: 0.36),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Text(
        'FREE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
