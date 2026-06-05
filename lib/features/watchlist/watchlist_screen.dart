import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/data/movie_repository.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/watchlist/application/watchlist_controller.dart';
import 'package:africanmovies/features/watchlist/widgets/watchlist_movie_card.dart';
import 'package:africanmovies/shared/widgets/app_button.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/responsive.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBrowseMovies;

  const WatchlistScreen({super.key, this.onBrowseMovies});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  String? _removingMovieId;

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);
    final watchlistState = ref.watch(watchlistControllerProvider);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: watchlistState.when(
                  loading: () => const _WatchlistLoadingState(),
                  error: (error, _) => _WatchlistErrorState(
                    message: _messageFor(error),
                    onRetry: () => ref.invalidate(watchlistControllerProvider),
                  ),
                  data: (movies) => _WatchlistContent(
                    movies: movies,
                    removingMovieId: _removingMovieId,
                    onMovieTap: _openMovieDetails,
                    onRemoveMovie: _removeFromWatchlist,
                    onBrowseMovies: widget.onBrowseMovies,
                  ),
                ),
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

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  Future<void> _removeFromWatchlist(Movie movie) async {
    if (_removingMovieId != null) return;

    setState(() => _removingMovieId = movie.id);

    try {
      final action = await ref
          .read(watchlistControllerProvider.notifier)
          .toggle(movie);

      if (!mounted) return;

      if (action == WatchlistAction.removed) {
        _showRemovedMessage(movie);
      } else {
        _showMessage('Added to watchlist');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _removingMovieId = null);
      }
    }
  }

  Future<void> _undoRemove(Movie movie) async {
    try {
      final action = await ref
          .read(watchlistControllerProvider.notifier)
          .toggle(movie);

      if (!mounted) return;

      _showMessage(
        action == WatchlistAction.added
            ? 'Restored to watchlist'
            : 'Removed from watchlist',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    }
  }

  void _showRemovedMessage(Movie movie) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          content: _UndoSnackBarContent(
            title: movie.title,
            onUndo: () {
              ScaffoldMessenger.of(
                context,
              ).hideCurrentSnackBar(reason: SnackBarClosedReason.action);
              _undoRemove(movie);
            },
          ),
        ),
      );
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
}

class _WatchlistContent extends StatelessWidget {
  final List<Movie> movies;
  final String? removingMovieId;
  final ValueChanged<Movie> onMovieTap;
  final ValueChanged<Movie> onRemoveMovie;
  final VoidCallback? onBrowseMovies;

  const _WatchlistContent({
    required this.movies,
    required this.removingMovieId,
    required this.onMovieTap,
    required this.onRemoveMovie,
    this.onBrowseMovies,
  });

  @override
  Widget build(BuildContext context) {
    final gridSpacing = Responsive.gridSpacing(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          _WatchlistHeader(movieCount: movies.length),
          SizedBox(height: 10.h),
          if (movies.isEmpty)
            _WatchlistEmptyState(onBrowseMovies: onBrowseMovies)
          else
            GridView.builder(
              itemCount: movies.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.posterGridColumns(context),
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: Responsive.isTablet(context) ? 14 : 0.h,
                childAspectRatio: Responsive.posterGridAspectRatio(context),
              ),
              itemBuilder: (_, index) {
                final movie = movies[index];

                return WatchlistMovieCard(
                  image: movie.displayPosterUrl,
                  title: movie.title,
                  genres: _genreLabel(movie),
                  duration: movie.durationLabel,
                  year: movie.yearLabel,
                  ageRating: movie.ageRatingLabel,
                  isRemoving: removingMovieId == movie.id,
                  onTap: () => onMovieTap(movie),
                  onPlayTap: () => onMovieTap(movie),
                  onMoreTap: () => onRemoveMovie(movie),
                );
              },
            ),
        ],
      ),
    );
  }

  String _genreLabel(Movie movie) {
    final genre = movie.genre.trim();
    if (genre.isNotEmpty) return genre;

    final releaseType = movie.releaseType.trim();
    if (releaseType.isNotEmpty) return releaseType;

    return 'Movie';
  }
}

class _UndoSnackBarContent extends StatelessWidget {
  final String title;
  final VoidCallback onUndo;

  const _UndoSnackBarContent({required this.title, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.heroButton.withValues(alpha: 0.14),
              border: Border.all(
                color: AppColors.heroButton.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.bookmark_remove_outlined,
              color: AppColors.heroButton,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '$title removed',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onUndo,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Container(
                height: 34.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.heroButton,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.heroButton),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.undo_rounded, color: Colors.white, size: 16.sp),
                    SizedBox(width: 5.w),
                    Text(
                      'Undo',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistHeader extends StatelessWidget {
  final int movieCount;

  const _WatchlistHeader({required this.movieCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Watchlist',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _titleCount(movieCount),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'All the movies and shows you’ve saved to watch later.',
          style: TextStyle(
            fontSize: 11.sp,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _titleCount(int count) {
    return count == 1 ? '1 Title' : '$count Titles';
  }
}

class _WatchlistLoadingState extends StatelessWidget {
  const _WatchlistLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          const _WatchlistHeader(movieCount: 0),
          SizedBox(height: 72.h),
          Center(
            child: SizedBox(
              width: 28.w,
              height: 28.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WatchlistErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          const _WatchlistHeader(movieCount: 0),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: AppColors.heroButton,
                  size: 36.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Unable to load watchlist',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                AppButton(
                  text: 'Retry',
                  width: 132.w,
                  height: 42.h,
                  fontSize: 13.sp,
                  borderRadius: AppRadius.sm,
                  backgroundColor: AppColors.heroButton,
                  borderColor: AppColors.heroButton,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistEmptyState extends StatelessWidget {
  final VoidCallback? onBrowseMovies;

  const _WatchlistEmptyState({this.onBrowseMovies});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 34.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.heroButton.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.heroButton.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.heroButton,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Your watchlist is empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add movies from the details screen and they’ll appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (onBrowseMovies != null) ...[
            SizedBox(height: 20.h),
            AppButton(
              text: 'Browse Movies',
              width: 156.w,
              height: 44.h,
              fontSize: 13.sp,
              borderRadius: AppRadius.sm,
              backgroundColor: AppColors.heroButton,
              borderColor: AppColors.heroButton,
              onPressed: onBrowseMovies,
            ),
          ],
        ],
      ),
    );
  }
}
