import 'package:africanmovies/features/auth/auth_screen.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_hero.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_info_card.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_purchase_button.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_small_action.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/section_movie_card.dart';

class MovieDetailsScreen extends ConsumerWidget {
  final Movie movie;

  const MovieDetailsScreen({super.key, required this.movie});

  bool _requireAuth(BuildContext context, WidgetRef ref) {
    final hasSession = ref.read(authControllerProvider).asData?.value != null;
    if (hasSession) return true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final relatedMovies = _relatedMovies(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MovieHero(movie: movie),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: MoviePurchaseButton(
                              icon: movie.isFree
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_outline_rounded,
                              title: movie.isFree
                                  ? 'Watch Now'
                                  : 'Watch for ${movie.priceLabel}',
                              subtitle: movie.isFree
                                  ? 'Free title'
                                  : 'Add to your library',
                              onTap: () {
                                _requireAuth(context, ref);
                              },
                            ),
                          ),
                          SizedBox(width: 6.w),
                          const MovieSmallAction(
                            icon: Icons.smart_display_outlined,
                            label: 'Trailer',
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: Icons.bookmark_add_outlined,
                            label: 'watchlist',
                            onTap: () {
                              _requireAuth(context, ref);
                            },
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: Icons.favorite_border_rounded,
                            label: 'Favorite',
                            onTap: () {
                              _requireAuth(context, ref);
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      _MovieDescription(description: movie.description),

                      SizedBox(height: 12.h),

                      MovieInfoCard(movie: movie),

                      if (relatedMovies.isNotEmpty) ...[
                        SizedBox(height: 14.h),

                        const SectionHeader(
                          title: 'More Like This',
                          actionText: 'See All »',
                        ),

                        SizedBox(height: 12.h),

                        SizedBox(
                          height: 168.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedMovies.length,
                            separatorBuilder: (_, _) => SizedBox(width: 8.w),
                            itemBuilder: (_, index) {
                              final relatedMovie = relatedMovies[index];

                              return SectionMovieCard(
                                image: relatedMovie.displayPosterUrl,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailsScreen(
                                        movie: relatedMovie,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Movie> _relatedMovies(WidgetRef ref) {
    final selectedGenre = movie.genre.trim().toLowerCase();
    if (selectedGenre.isEmpty) return const [];

    return ref
        .watch(homeDataProvider)
        .maybeWhen(
          data: (data) => data.movies
              .where(
                (relatedMovie) =>
                    relatedMovie.id != movie.id &&
                    relatedMovie.genre.trim().toLowerCase() == selectedGenre,
              )
              .take(12)
              .toList(),
          orElse: () => const <Movie>[],
        );
  }
}

class _MovieDescription extends StatefulWidget {
  final String description;

  const _MovieDescription({required this.description});

  @override
  State<_MovieDescription> createState() => _MovieDescriptionState();
}

class _MovieDescriptionState extends State<_MovieDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.description.trim();
    if (description.isEmpty) return const SizedBox.shrink();

    final canExpand = description.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
        if (canExpand) ...[
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded ? 'Read Less' : 'Read More',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heroButton,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.heroButton,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
