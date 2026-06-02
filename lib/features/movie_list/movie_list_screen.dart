import 'package:africanmovies/features/favorite/widgets/favorite_movie_card.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  static const _movieList = [
    _Movies(
      image: AppAssets.poster1,
      title: 'Living Sacrifice',
      genres: 'Drama, Thriller',
      duration: '2h 15m',
      year: '2024',
      ageRating: '16+',
    ),
    _Movies(
      image: AppAssets.poster2,
      title: 'Brotherhood: A Son\'s Affair',
      genres: 'Drama',
      duration: '2h 10m',
      year: '2023',
      ageRating: '16+',
    ),
    _Movies(
      image: AppAssets.poster3,
      title: 'Chief Daddy',
      genres: 'Comedy, Drama',
      duration: '1h 53m',
      year: '2021',
      ageRating: '13+',
    ),
    _Movies(
      image: AppAssets.poster19,
      title: 'Ibu And Kezia',
      genres: 'Comedy',
      duration: '2h 15m',
      year: '2024',
      ageRating: '16+',
    ),
    _Movies(
      image: AppAssets.poster20,
      title: 'Cherikoko\'s Return',
      genres: 'Drama',
      duration: '2h 10m',
      year: '2023',
      ageRating: '16+',
    ),
    _Movies(
      image: AppAssets.poster18,
      title: 'Osufua In London',
      genres: 'Comedy, Drama',
      duration: '1h 53m',
      year: '2021',
      ageRating: '13+',
    ),
    _Movies(
      image: AppAssets.poster4,
      title: 'Her Life Journey',
      genres: 'Drama, Romance',
      duration: '2h 20m',
      year: '2024',
      ageRating: '16+',
    ),
    _Movies(
      image: AppAssets.poster5,
      title: 'The Bridge',
      genres: 'Crime, Thriller',
      duration: '2h 05m',
      year: '2023',
      ageRating: '16+',
    ),
    _Movies(
      image: AppAssets.poster6,
      title: 'A Western Love Story',
      genres: 'Romance, Drama',
      duration: '2h 18m',
      year: '2023',
      ageRating: '13+',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);
    final gridSpacing = Responsive.gridSpacing(context);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.h),

                  Text(
                    'Movies Type',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    '${_movieList.length} Titles',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    'The list of movie type will show here.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  GridView.builder(
                    itemCount: _movieList.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.posterGridColumns(context),
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: Responsive.isTablet(context) ? 14 : 0.h,
                      childAspectRatio: Responsive.posterGridAspectRatio(
                        context,
                      ),
                    ),
                    itemBuilder: (_, index) {
                      final movie = _movieList[index];

                      return FavoriteMovieCard(
                        image: movie.image,
                        title: movie.title,
                        genres: movie.genres,
                        duration: movie.duration,
                        year: movie.year,
                        ageRating: movie.ageRating,
                        onTap: () {},
                        onPlayTap: () {},
                        onMoreTap: () {
                          //print("from other screen");
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: headerHeight,
              child: const AppScreenHeader(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Movies {
  final String image;
  final String title;
  final String genres;
  final String duration;
  final String year;
  final String ageRating;

  const _Movies({
    required this.image,
    required this.title,
    required this.genres,
    required this.duration,
    required this.year,
    required this.ageRating,
  });
}
