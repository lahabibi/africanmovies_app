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
  final bool isTrailerLoading;
  final VoidCallback? onWatchNowTap;
  final VoidCallback? onTrailerTap;

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
    this.isTrailerLoading = false,
    this.onWatchNowTap,
    this.onTrailerTap,
  });

  String _formatTitle(String title) {
    final words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final firstLineWordCount = switch (words.length) {
      2 => 1,
      3 || 4 => 2,
      5 || 6 => 3,
      _ => null,
    };

    if (firstLineWordCount == null) {
      return title.trim();
    }

    return '${words.take(firstLineWordCount).join(' ')}\n${words.skip(firstLineWordCount).join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompactPhone =
        screenSize.shortestSide < 600 && screenSize.height <= 700;
    final bannerPadding = isCompactPhone ? 12.w : 14.w;
    final titleFontSize = isCompactPhone ? 24.sp : 30.sp;
    final descriptionMaxLines = isCompactPhone ? 1 : 2;
    final sectionGap = isCompactPhone ? 6.h : 10.h;
    final buttonHeight = isCompactPhone ? 28.h : 32.h;
    final buttonFontSize = isCompactPhone ? 10.5.sp : 12.sp;
    final playButtonWidth = isCompactPhone ? 102.w : 110.w;
    final trailerButtonWidth = isCompactPhone ? 78.w : 82.w;

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
            padding: EdgeInsets.all(bannerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FEATURED MOVIE',
                  style: TextStyle(
                    fontSize: isCompactPhone ? 6.5.sp : 7.sp,
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
                    fontSize: titleFontSize,
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

                SizedBox(height: sectionGap),

                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenSize.width * 0.5),
                  child: Text(
                    description,
                    maxLines: descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompactPhone ? 7.5.sp : 8.sp,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: sectionGap),

                Row(
                  children: [
                    Flexible(child: _MetaText(year, compact: isCompactPhone)),
                    _Dot(compact: isCompactPhone),
                    Flexible(child: _MetaText(genre, compact: isCompactPhone)),
                    _Dot(compact: isCompactPhone),
                    Flexible(
                      flex: 2,
                      child: _MetaText(releaseType, compact: isCompactPhone),
                    ),
                    _Dot(compact: isCompactPhone),
                    Flexible(
                      child: _MetaText(duration, compact: isCompactPhone),
                    ),
                    SizedBox(width: 8.w),
                    _AgeBadge(ageRating, compact: isCompactPhone),
                  ],
                ),

                SizedBox(height: isCompactPhone ? 8.h : 12.h),

                Row(
                  children: [
                    AppButton(
                      text: 'Watch Now',
                      width: playButtonWidth,
                      height: buttonHeight,
                      fontSize: buttonFontSize,
                      borderRadius: AppRadius.xs,
                      borderColor: AppColors.heroButton,
                      backgroundColor: AppColors.heroButton,
                      icon: Icon(
                        Icons.play_arrow_rounded,
                        size: isCompactPhone ? 14.sp : 16.sp,
                      ),
                      onPressed: onWatchNowTap ?? () {},
                    ),
                    SizedBox(width: 12.w),
                    AppButton(
                      text: 'Trailer',
                      width: trailerButtonWidth,
                      height: buttonHeight,
                      fontSize: buttonFontSize,
                      borderRadius: AppRadius.xs,
                      variant: AppButtonVariant.outline,
                      borderColor: AppColors.textPrimary,
                      onPressed: isTrailerLoading
                          ? null
                          : onTrailerTap ?? () {},
                      icon: isTrailerLoading
                          ? SizedBox.square(
                              dimension: 13.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : null,
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
  final bool compact;

  const _MetaText(this.text, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 7.5.sp : 8.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.82),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool compact;

  const _Dot({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4.w : 6.w),
      child: Text(
        '•',
        style: TextStyle(
          fontSize: compact ? 9.sp : 11.sp,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _AgeBadge extends StatelessWidget {
  final String text;
  final bool compact;

  const _AgeBadge(this.text, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4.w : 5.w,
        vertical: compact ? 1.5.h : 2.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: compact ? 8.5.sp : 10.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
