import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class MoviePosterCard extends StatelessWidget {
  final String image;
  final String? title;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool showGradient;

  const MoviePosterCard({
    super.key,
    required this.image,
    this.title,
    this.width = 150,
    this.height = 220,
    this.onTap,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width.w,
        height: height.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.cardBorder,
          ),
        ),
        child: Stack(
          children: [
            /// Poster image
            Positioned.fill(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
              ),
            ),

            /// Gradient overlay
            if (showGradient)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

            /// Title
            if (title != null)
              Positioned(
                left: 14.w,
                right: 14.w,
                bottom: 14.h,
                child: Text(
                  title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}