import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../movies/domain/movie.dart';
import '../../../shared/widgets/section_header.dart';
import 'language_movie_card.dart';

class LanguageSection extends StatelessWidget {
  final String language;
  final List<Movie> movies;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<Movie>? onMovieTap;

  const LanguageSection({
    super.key,
    required this.language,
    required this.movies,
    this.onSeeAllTap,
    this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: language,
          actionText: 'See All »',
          onActionTap: onSeeAllTap,
        ),
        Text(
          _countLabel(movies.length),
          style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9CA3AF)),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 156.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => SizedBox(width: 6.w),
            itemBuilder: (_, index) {
              final movie = movies[index];

              return LanguageMovieCard(
                image: movie.displayPosterUrl,
                year: movie.yearLabel,
                genre: movie.genre,
                ageRating: movie.ageRatingLabel,
                onTap: () => onMovieTap?.call(movie),
              );
            },
          ),
        ),
      ],
    );
  }

  String _countLabel(int count) {
    return count == 1 ? '1 Movie' : '$count Movies';
  }
}
