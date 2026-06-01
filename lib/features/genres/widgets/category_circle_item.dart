import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class CategoryCircleItem extends StatelessWidget {
  final String label;
  final String image;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryCircleItem({
    super.key,
    required this.label,
    required this.image,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 46.w,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44.w,
              height: 44.w,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.28),
                  width: 1.2,
                ),
              ),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                color: selected
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),

            SizedBox(height: 4.h),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}