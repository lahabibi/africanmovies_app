import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_image.dart';

enum HeroBannerType { image, video }

class HeroBanner extends StatelessWidget {
  final HeroBannerType type;
  final String image;
  final String title;
  final String description;
  final String year;
  final String genre;
  final String releaseType;
  final String duration;
  final String ageRating;
  final String? videoUrl;

  const HeroBanner({
    super.key,
    required this.type,
    required this.image,
    required this.title,
    required this.description,
    required this.year,
    required this.genre,
    required this.releaseType,
    required this.duration,
    required this.ageRating,
    this.videoUrl,
  });

  String _formatTitle(String title) {
    final words = title.trim().split(' ');

    if (words.length == 2) {
      return '${words[0]}\n${words[1]}';
    }

    if (words.length == 3) {
      return '${words[0]} ${words[1]}\n${words[2]}';
    }

    return title;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: AppImage(source: image)),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28), //10
                    Colors.black.withValues(alpha: 0.98), //78
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FEATURED MOVIE',
                  style: TextStyle(
                    fontSize: 7.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),

                const Spacer(),

                Text(
                  _formatTitle(title).toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 30.sp,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.75),
                        offset: Offset(0, 2.h),
                        blurRadius: 6.r,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.5,
                  ),
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.sp,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                Row(
                  children: [
                    _MetaText(year),
                    _Dot(),
                    _MetaText(genre),
                    _Dot(),
                    _MetaText(releaseType),
                    _Dot(),
                    _MetaText(duration),
                    SizedBox(width: 8.w),
                    _AgeBadge(ageRating),
                  ],
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    AppButton(
                      text: 'Watch Now',
                      width: 110.w,
                      height: 32.h,
                      fontSize: 12.sp,
                      borderRadius: AppRadius.xs,
                      borderColor: AppColors.heroButton,
                      backgroundColor: AppColors.heroButton,
                      icon: Icon(Icons.play_arrow_rounded, size: 16.sp),
                    ),
                    SizedBox(width: 12.w),
                    AppButton(
                      text: 'Trailer',
                      width: 82.w,
                      height: 32.h,
                      fontSize: 12.sp,
                      borderRadius: AppRadius.xs,
                      variant: AppButtonVariant.outline,
                      borderColor: AppColors.textPrimary,
                      // icon: Icon(
                      //   Icons.play_arrow_outlined,
                      //   size: 18.sp,
                      // ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final String text;

  const _MetaText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.82),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Text(
        '•',
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _AgeBadge extends StatelessWidget {
  final String text;

  const _AgeBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
