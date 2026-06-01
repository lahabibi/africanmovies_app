import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class GenreFilterBar extends StatelessWidget {
  final String title;
  final int movieCount;
  final VoidCallback? onSortTap;
  final String sortValue;

  const GenreFilterBar({
    super.key,
    required this.title,
    required this.movieCount,
    this.sortValue = 'Titles',
    this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: '  •  $movieCount Movies',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        GestureDetector(
          onTap: onSortTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                sortValue,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}