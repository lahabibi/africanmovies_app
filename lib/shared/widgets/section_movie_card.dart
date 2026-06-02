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
  final VoidCallback? onTap;

  const SectionMovieCard({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.borderRadius,
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
        child: AppImage(source: image),
      ),
    );
  }
}
