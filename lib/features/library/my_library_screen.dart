import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/library/widgets/library_continue_card.dart';
import 'package:africanmovies/features/library/widgets/library_movie_card.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({super.key});

  static const _continueWatchingMovies = [
    _LibraryContinueMovie(
      image: AppAssets.poster5,
      progress: 0.70,
      progressText: '70% watched',
      timeLeft: '48m left',
      expiryText: 'Expires in 5 days',
    ),
    _LibraryContinueMovie(
      image: AppAssets.poster1,
      progress: 0.40,
      progressText: '45% watched',
      timeLeft: '1h 02m left',
      expiryText: 'Expires in 3 days',
    ),
    _LibraryContinueMovie(
      image: AppAssets.poster3,
      progress: 0.90,
      progressText: '20% watched',
      timeLeft: '1h 23m left',
      expiryText: 'Expires in 8 days',
    ),
  ];

  static const _purchasedMovies = [
    _LibraryMovie(
      image: AppAssets.poster1,
      expiryText: 'Expires in 7 days',
      actionText: 'Watch Now',
    ),
    _LibraryMovie(
      image: AppAssets.poster6,
      expiryText: 'Expires in 12 days',
      actionText: 'Watch Now',
    ),
    _LibraryMovie(
      image: AppAssets.poster7,
      expiryText: 'Expires in 4 days',
      actionText: 'Watch Now',
    ),
    _LibraryMovie(
      image: AppAssets.poster8,
      expiryText: 'Expires in 9 days',
      actionText: 'Watch Now',
    ),
  ];

  static const _expiringSoonMovies = [
    _LibraryMovie(
      image: AppAssets.poster9,
      expiryBadgeText: '12h left',
      expiryText: 'Expires tomorrow',
      actionText: 'Resume',
    ),
    _LibraryMovie(
      image: AppAssets.poster10,
      expiryBadgeText: '2 days left',
      expiryText: 'Expires in 2 days',
      actionText: 'Resume',
    ),
    _LibraryMovie(
      image: AppAssets.poster11,
      expiryBadgeText: '3 days left',
      expiryText: 'Expires in 3 days',
      actionText: 'Watch Now',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),

                  Text(
                    'My Library',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  Text(
                    'Purchased movies available for streaming.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.heroButton,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '12 Movies',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Active Access',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heroButton,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  const SectionHeader(
                    title: 'Continue Watching',
                    actionText: 'See All »',
                  ),

                  SizedBox(height: 12.h),

                  SizedBox(
                    height: 260.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _continueWatchingMovies.length,
                      separatorBuilder: (_, _) => SizedBox(width: 10.w),
                      itemBuilder: (_, index) {
                        final movie = _continueWatchingMovies[index];

                        return LibraryContinueCard(
                          image: movie.image,
                          progress: movie.progress,
                          progressText: movie.progressText,
                          timeLeft: movie.timeLeft,
                          expiryText: movie.expiryText,
                          onTap: () {},
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 14.h),

                  const SectionHeader(
                    title: 'My Movies (All Purchased)',
                    actionText: 'See All »',
                  ),

                  SizedBox(height: 12.h),

                  SizedBox(
                    height: 230.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _purchasedMovies.length,
                      separatorBuilder: (_, _) => SizedBox(width: 8.w),
                      itemBuilder: (_, index) {
                        final movie = _purchasedMovies[index];

                        return LibraryMovieCard(
                          image: movie.image,
                          expiryText: movie.expiryText,
                          actionText: movie.actionText,
                        );
                      },
                    ),
                  ),

                  const SectionHeader(
                    title: 'Expiring Soon',
                    actionText: 'See All »',
                  ),

                  SizedBox(height: 12.h),

                  SizedBox(
                    height: 230.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _expiringSoonMovies.length,
                      separatorBuilder: (_, _) => SizedBox(width: 8.w),
                      itemBuilder: (_, index) {
                        final movie = _expiringSoonMovies[index];

                        return LibraryMovieCard(
                          image: movie.image,
                          expiryText: movie.expiryText,
                          actionText: movie.actionText,
                          expiryBadgeText: movie.expiryBadgeText,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: headerHeight, child: const HomeHeader()),
          ),
        ],
      ),
    );
  }
}

class _LibraryContinueMovie {
  final String image;
  final String progressText;
  final String timeLeft;
  final String expiryText;
  final double progress;

  const _LibraryContinueMovie({
    required this.image,
    required this.progressText,
    required this.timeLeft,
    required this.expiryText,
    required this.progress,
  });
}

class _LibraryMovie {
  final String image;
  final String expiryText;
  final String actionText;
  final String? expiryBadgeText;

  const _LibraryMovie({
    required this.image,
    required this.expiryText,
    required this.actionText,
    this.expiryBadgeText,
  });
}
