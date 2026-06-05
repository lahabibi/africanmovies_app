import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_context_menu.dart';
import '../../../shared/widgets/app_image.dart';

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
  final IconData menuIcon;
  final String menuTitle;
  final String? menuSubtitle;
  final bool isMenuLoading;

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
    this.menuIcon = Icons.play_arrow_rounded,
    this.menuTitle = 'Watch Now',
    this.menuSubtitle = '\$0.99',
    this.isMenuLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.66,
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: AppImage(source: image)),

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
                          icon: menuIcon,
                          title: isMenuLoading ? 'Removing...' : menuTitle,
                          subtitle: isMenuLoading ? null : menuSubtitle,
                          onTap: isMenuLoading ? null : onMoreTap,
                        ),
                      ],
                      child: Container(
                        width: 26.w,
                        height: 26.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.42),
                        ),
                        child: isMenuLoading
                            ? SizedBox(
                                width: 12.w,
                                height: 12.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 8.w,
                    bottom: 8.h,
                    child: GestureDetector(
                      onTap: onPlayTap,
                      child: Container(
                        width: 22.w,
                        height: 22.w,
                        alignment: Alignment.center,
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
            style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
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
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(color: AppColors.cardBorder),
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
