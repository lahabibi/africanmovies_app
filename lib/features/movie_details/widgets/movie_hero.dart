import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_image.dart';
import '../../movies/domain/movie.dart';

class MovieHero extends StatelessWidget {
  final Movie movie;

  const MovieHero({super.key, required this.movie});

  String _formatTitle(String title) {
    final words = title.trim().split(RegExp(r'\s+'));

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
    final horizontalPadding = Responsive.horizontalPadding(context);
    final metaItems = [
      movie.yearLabel,
      movie.genre,
      movie.releaseType,
      movie.durationLabel,
      movie.ageRatingLabel,
    ].where((item) => item.trim().isNotEmpty && item != 'N/A').toList();

    return SizedBox(
      height: Responsive.detailHeroHeight(context),
      child: Stack(
        children: [
          Positioned.fill(
            child: AppImage(source: movie.displayBannerUrl, fit: BoxFit.cover),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.15),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.paddingOf(context).top + 16.h,
            left: horizontalPadding,
            child: _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          //TODO: Share movie on social media
          // Positioned(
          //   top: MediaQuery.paddingOf(context).top + 16.h,
          //   right: horizontalPadding,
          //   child: _CircleIconButton(
          //     icon: Icons.ios_share_rounded,
          //     onTap: () {},
          //   ),
          // ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTitle(movie.title).toUpperCase(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 42.sp,
                          height: .88,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: [
                          for (final item in metaItems) _MetaChip(item),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      Row(
                        children: [
                          Icon(
                            movie.isFree
                                ? Icons.play_circle_fill_rounded
                                : Icons.lock_rounded,
                            color: AppColors.heroButton,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              movie.isFree ? 'Free title' : movie.priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (movie.status.trim().isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            _StatusPill(movie.status),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 16.sp),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;

  const _MetaChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      constraints: BoxConstraints(
        maxWidth: Responsive.isTablet(context) ? 160 : 116.w,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10.sp, color: Colors.white),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.heroButton),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.heroButton,
        ),
      ),
    );
  }
}
