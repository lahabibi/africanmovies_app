import 'package:africanmovies/features/favorite/widgets/favorite_movie_card.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class MovieListScreen extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const MovieListScreen({super.key, required this.title, required this.movies});

  void _openMovieDetails(BuildContext context, Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

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
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    '${movies.length} Titles',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  GridView.builder(
                    itemCount: movies.length,
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
                      final movie = movies[index];

                      return FavoriteMovieCard(
                        image: movie.displayPosterUrl,
                        title: movie.title,
                        genres: movie.genre,
                        duration: movie.durationLabel,
                        year: movie.yearLabel,
                        ageRating: movie.ageRatingLabel,
                        onTap: () => _openMovieDetails(context, movie),
                        onPlayTap: () {},
                        onMoreTap: () {},
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
