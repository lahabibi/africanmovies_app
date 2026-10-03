import 'package:africanmovies/core/network/api_exception.dart';
import 'package:africanmovies/features/favorite/widgets/favorite_movie_card.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/player/application/player_providers.dart';
import 'package:africanmovies/features/player/movie_player_screen.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class MovieListScreen extends ConsumerStatefulWidget {
  final String title;
  final List<Movie> movies;

  const MovieListScreen({super.key, required this.title, required this.movies});

  @override
  ConsumerState<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends ConsumerState<MovieListScreen> {
  String? _openingMovieId;

  void _openMovieDetails(BuildContext context, Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  Future<void> _openMoviePlayer(Movie movie) async {
    if (_openingMovieId != null) return;

    setState(() => _openingMovieId = movie.id);

    try {
      final playback = await ref
          .read(playerRepositoryProvider)
          .requestMoviePlayback(movie.id);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MoviePlayerScreen(playback: playback),
        ),
      );

      if (!mounted) return;
      ref.invalidate(homeDataProvider);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _openingMovieId = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);
    final gridSpacing = Responsive.gridSpacing(context);
    final activeLibraryMovieIds = ref
        .watch(homeDataProvider)
        .maybeWhen(
          data: (data) =>
              data.activeLibraryOrders.map((order) => order.movieId).toSet(),
          orElse: () => const <String>{},
        );

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
                    widget.title,
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
                    '${widget.movies.length} Titles',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  GridView.builder(
                    itemCount: widget.movies.length,
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
                      final movie = widget.movies[index];
                      final hasActiveAccess = activeLibraryMovieIds.contains(
                        movie.id,
                      );
                      final isOpening = _openingMovieId == movie.id;
                      final openMovie = hasActiveAccess
                          ? () => _openMoviePlayer(movie)
                          : () => _openMovieDetails(context, movie);

                      return FavoriteMovieCard(
                        image: movie.displayPosterUrl,
                        title: movie.title,
                        genres: movie.genre,
                        duration: movie.durationLabel,
                        year: movie.yearLabel,
                        ageRating: movie.ageRatingLabel,
                        menuSubtitle: hasActiveAccess ? null : movie.priceLabel,
                        showPlayAction: hasActiveAccess,
                        isPlayLoading: isOpening,
                        onTap: isOpening ? null : openMovie,
                        onPlayTap: hasActiveAccess && !isOpening
                            ? () => _openMoviePlayer(movie)
                            : null,
                        onMoreTap: isOpening ? null : openMovie,
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
