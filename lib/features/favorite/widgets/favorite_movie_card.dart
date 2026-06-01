import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_context_menu.dart';

class FavoriteMovieCard extends StatelessWidget {
  final String image;
  final String title;
  final String genres;
  final String duration;
  final String year;
  final String ageRating;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onPlayTap;

  const FavoriteMovieCard({
    super.key,
    required this.image,
    required this.title,
    required this.genres,
    required this.duration,
    required this.year,
    required this.ageRating,
    this.onTap,
    this.onMoreTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180.h,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 0.8,
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

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: AppContextMenu(
                    items: [
                      AppContextMenuItem(
                        icon: Icons.play_arrow_rounded,
                        title: 'Watch Now',
                        subtitle: '\$0.99',
                        onTap: onMoreTap,
                      ),
                    ],
                    child: Container(
                      width: 26.w,
                      height: 26.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.42),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  )
                ),

                Positioned(
                  left: 8.w,
                  bottom: 8.h,
                  child: GestureDetector(
                    onTap: onPlayTap,
                    child: Container(
                      width: 22.w,
                      height: 22.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.42),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 6.h),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.15,
            ),
          ),

          SizedBox(height: 4.h),

          Text(
            genres,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: 4.h),

          Row(
            children: [
              Expanded(
                child: Text(
                  '$duration  •  $year',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 5.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  ageRating,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}