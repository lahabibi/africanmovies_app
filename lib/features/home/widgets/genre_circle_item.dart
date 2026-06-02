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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 42.w,
        child: Column(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              padding: EdgeInsets.all(10.w),
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
            SizedBox(height: 8.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.sp,
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
