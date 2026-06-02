import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';

class MovieHero extends StatelessWidget {
  const MovieHero({super.key});

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
    final horizontalPadding = Responsive.horizontalPadding(context);

    return SizedBox(
      height: Responsive.detailHeroHeight(context),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AppAssets.banner3, fit: BoxFit.cover),
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

          Positioned(
            top: MediaQuery.paddingOf(context).top + 16.h,
            right: horizontalPadding,
            child: _CircleIconButton(
              icon: Icons.ios_share_rounded,
              onTap: () {},
            ),
          ),

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
                        _formatTitle('living sacrifice').toUpperCase(),
                        style: TextStyle(
                          fontSize: 42.sp,
                          height: .88,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Row(
                        children: [
                          _MetaChip('2024'),
                          _Dot(),
                          _MetaChip('Drama'),
                          _Dot(),
                          _MetaChip('Thriller'),
                          _Dot(),
                          _MetaChip('2h 15m'),
                          _Dot(),
                          _MetaChip('16+'),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: const Color(0xFFFFC107),
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '8.6',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(color: AppColors.heroButton),
                            ),
                            child: Text(
                              'TOP 10',
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.heroButton,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '#2 in Drama Today',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.sp, color: Colors.white),
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
        style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
      ),
    );
  }
}
