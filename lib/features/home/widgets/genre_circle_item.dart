import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_image.dart';

class GenreCircleItem extends StatelessWidget {
  final String label;
  final String image;
  final VoidCallback? onTap;

  const GenreCircleItem({
    super.key,
    required this.label,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompactPhone = size.shortestSide < 600 && size.height <= 700;
    final itemWidth = isCompactPhone ? 42.w : 44.w;
    final iconSize = isCompactPhone ? 42.w : 46.w;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              padding: EdgeInsets.all(isCompactPhone ? 7.w : 8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30),
                  width: 1.1,
                ),
              ),
              child: AppImage(
                source: image,
                fit: BoxFit.contain,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: isCompactPhone ? 3.h : 5.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompactPhone ? 9.2.sp : 10.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
