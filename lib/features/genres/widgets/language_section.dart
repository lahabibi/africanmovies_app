import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/widgets/section_header.dart';
import 'language_movie_card.dart';

class LanguageSection extends StatelessWidget {
  final String language;
  final int movieCount;
  final List<LanguageMovieItem> movies;

  const LanguageSection({
    super.key,
    required this.language,
    required this.movieCount,
    required this.movies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: language, actionText: 'See All »'),
        Text(
          '$movieCount Movies',
          style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9CA3AF)),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 156.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, _) => SizedBox(width: 6.w),
            itemBuilder: (_, index) {
              final movie = movies[index];

              return LanguageMovieCard(
                image: movie.image,
                year: movie.year,
                genre: movie.genre,
                ageRating: movie.ageRating,
              );
            },
          ),
        ),
      ],
    );
  }
}

class LanguageMovieItem {
  final String image;
  final String year;
  final String genre;
  final String ageRating;

  const LanguageMovieItem({
    required this.image,
    required this.year,
    required this.genre,
    required this.ageRating,
  });
}
