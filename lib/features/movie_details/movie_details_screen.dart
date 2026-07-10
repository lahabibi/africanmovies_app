import 'package:africanmovies/features/auth/auth_screen.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/favorite/application/favorite_controller.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_hero.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_info_card.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_purchase_button.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_small_action.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/data/movie_repository.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/payment/application/payment_providers.dart';
import 'package:africanmovies/features/player/application/player_providers.dart';
import 'package:africanmovies/features/player/movie_player_screen.dart';
import 'package:africanmovies/features/player/trailer_player_screen.dart';
import 'package:africanmovies/features/watchlist/application/watchlist_controller.dart';
import 'package:africanmovies/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/section_movie_card.dart';

class MovieDetailsScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

enum _MovieAccessState { active, freeAvailable, paymentRequired }

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  bool _isTogglingWatchlist = false;
  bool _isTogglingFavorite = false;
  bool _isOpeningPlayer = false;
  bool _isOpeningTrailer = false;

  Movie get movie => widget.movie;

  bool _requireAuth(BuildContext context, WidgetRef ref) {
    final hasSession = ref.read(authControllerProvider).asData?.value != null;
    if (hasSession) return true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return false;
  }

  void _openMovieList(BuildContext context, List<Movie> movies) {
    if (movies.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MovieListScreen(title: 'More Like This', movies: movies),
      ),
    );
  }

  Future<void> _toggleWatchlist() async {
    if (_isTogglingWatchlist) return;
    if (!_requireAuth(context, ref)) return;

    setState(() => _isTogglingWatchlist = true);

    try {
      final action = await ref
          .read(watchlistControllerProvider.notifier)
          .toggle(movie);

      if (!mounted) return;

      _showMessage(
        action == WatchlistAction.added
            ? 'Added to watchlist'
            : 'Removed from watchlist',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isTogglingWatchlist = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    if (!_requireAuth(context, ref)) return;

    setState(() => _isTogglingFavorite = true);

    try {
      final action = await ref
          .read(favoriteControllerProvider.notifier)
          .toggle(movie);

      if (!mounted) return;

      _showMessage(
        action == FavoriteAction.added
            ? 'Added to favorites'
            : 'Removed from favorites',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
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

  Future<void> _handleWatchNow(_MovieAccessState accessState) async {
    if (!_requireAuth(context, ref)) return;

    switch (accessState) {
      case _MovieAccessState.active:
        await _openMoviePlayer();
      case _MovieAccessState.freeAvailable:
        final shouldClaim = await _showFreeMovieConfirmation();
        if (shouldClaim == true && mounted) {
          await _openMoviePlayer();
        }
      case _MovieAccessState.paymentRequired:
        await _startPurchaseFlow();
    }
  }

  Future<void> _startPurchaseFlow() async {
    final shouldPurchase = await _showNativePurchaseConfirmation();
    if (shouldPurchase != true || !mounted) return;

    final result = await ref
        .read(purchaseControllerProvider.notifier)
        .purchaseMovie(context: context, movie: movie);

    if (mounted) _showMessage(result.message);
  }

  Future<bool?> _showNativePurchaseConfirmation() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, bottomInset + 14.h),
          child: Container(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.heroButton.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.heroButton.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_open_rounded,
                        color: AppColors.heroButton,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase movie',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'App price',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        movie.priceLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Your store will show the final localized price before you confirm.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Cancel',
                        height: 44.h,
                        fontSize: 13.sp,
                        borderRadius: AppRadius.sm,
                        backgroundColor: Colors.transparent,
                        borderColor: AppColors.cardBorder,
                        textColor: AppColors.textSecondary,
                        onPressed: () => Navigator.pop(sheetContext, false),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: AppButton(
                        text: 'Continue',
                        height: 44.h,
                        fontSize: 13.sp,
                        borderRadius: AppRadius.sm,
                        backgroundColor: AppColors.heroButton,
                        borderColor: AppColors.heroButton,
                        onPressed: () => Navigator.pop(sheetContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMoviePlayer() async {
    if (_isOpeningPlayer) return;

    setState(() => _isOpeningPlayer = true);

    var shouldOfferPurchase = false;

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
      shouldOfferPurchase =
          error is ApiException &&
          error.statusCode == 403 &&
          movie.price > 0 &&
          !_isPurchaseInProgress;
    } finally {
      if (mounted) {
        setState(() => _isOpeningPlayer = false);
      }
    }

    if (shouldOfferPurchase && mounted) {
      await _startPurchaseFlow();
    }
  }

  bool get _isPurchaseInProgress {
    return ref.read(purchaseControllerProvider).isLoading;
  }

  Future<bool?> _showFreeMovieConfirmation() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final maxWidth = Responsive.isTablet(sheetContext)
            ? 470.0
            : double.infinity;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, bottomInset + 14.h),
              child: Container(
                padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 30.r,
                      offset: Offset(0, 18.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.heroButton.withValues(alpha: 0.14),
                            border: Border.all(
                              color: AppColors.heroButton.withValues(
                                alpha: 0.36,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            color: AppColors.heroButton,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Claim free movie?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Free',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'We will add this movie to your library and start your watch period when playback opens. Free access can only be claimed once.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cancel',
                            height: 44.h,
                            fontSize: 13.sp,
                            borderRadius: AppRadius.sm,
                            backgroundColor: Colors.transparent,
                            borderColor: AppColors.cardBorder,
                            textColor: AppColors.textSecondary,
                            onPressed: () => Navigator.pop(sheetContext, false),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: AppButton(
                            text: 'Claim & Watch',
                            height: 44.h,
                            fontSize: 13.sp,
                            borderRadius: AppRadius.sm,
                            backgroundColor: AppColors.heroButton,
                            borderColor: AppColors.heroButton,
                            icon: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 17.sp,
                            ),
                            onPressed: () => Navigator.pop(sheetContext, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTrailer() async {
    if (_isOpeningTrailer) return;
    setState(() => _isOpeningTrailer = true);

    try {
      final playback = await ref
          .read(playerRepositoryProvider)
          .requestTrailerPlayback(movie.id);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrailerPlayerScreen(
            title: playback.title.isNotEmpty ? playback.title : movie.title,
            videoUrl: playback.playbackUrl,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _isOpeningTrailer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final homeDataState = ref.watch(homeDataProvider);
    final relatedMovies = _relatedMovies(homeDataState);
    final hasSession = ref.watch(authControllerProvider).asData?.value != null;
    final accessState = _movieAccessState(homeDataState);
    final hasAccess = accessState != _MovieAccessState.paymentRequired;
    final purchaseState = ref.watch(purchaseControllerProvider);
    final isPurchasing = purchaseState.isLoading || _isOpeningPlayer;
    final watchlistState = hasSession
        ? ref.watch(watchlistControllerProvider)
        : const AsyncData<List<Movie>>([]);
    final favoriteState = hasSession
        ? ref.watch(favoriteControllerProvider)
        : const AsyncData<List<Movie>>([]);
    final isInWatchlist = hasSession && _isMovieInWatchlist(watchlistState);
    final isFavorite = hasSession && _isMovieFavorite(favoriteState);

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
                              icon: hasAccess
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_outline_rounded,
                              title: _watchButtonTitle(accessState),
                              subtitle: _watchButtonSubtitle(accessState),
                              isLoading: isPurchasing,
                              onTap: isPurchasing
                                  ? null
                                  : () => _handleWatchNow(accessState),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: Icons.smart_display_outlined,
                            label: 'Trailer',
                            isLoading: _isOpeningTrailer,
                            onTap: _openTrailer,
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: isInWatchlist
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            label: isInWatchlist ? 'Saved' : 'Watchlist',
                            isActive: isInWatchlist,
                            isLoading: _isTogglingWatchlist,
                            onTap: _toggleWatchlist,
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: isFavorite ? 'Liked' : 'Favorite',
                            isActive: isFavorite,
                            isLoading: _isTogglingFavorite,
                            onTap: _toggleFavorite,
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      _MovieDescription(description: movie.description),

                      SizedBox(height: 12.h),

                      MovieInfoCard(movie: movie),

                      if (relatedMovies.isNotEmpty) ...[
                        SizedBox(height: 14.h),

                        SectionHeader(
                          title: 'More Like This',
                          actionText: 'See All »',
                          onActionTap: () {
                            _openMovieList(context, relatedMovies);
                          },
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

  bool _isMovieInWatchlist(AsyncValue<List<Movie>> watchlistState) {
    return watchlistState.when(
      data: (movies) => movies.any((movie) => movie.id == widget.movie.id),
      loading: () => widget.movie.inWatchlist,
      error: (_, _) => widget.movie.inWatchlist,
    );
  }

  bool _isMovieFavorite(AsyncValue<List<Movie>> favoriteState) {
    return favoriteState.when(
      data: (movies) => movies.any((movie) => movie.id == widget.movie.id),
      loading: () => widget.movie.isFavorite,
      error: (_, _) => widget.movie.isFavorite,
    );
  }

  _MovieAccessState _movieAccessState(AsyncValue<HomeData> homeDataState) {
    return homeDataState.maybeWhen(
      data: (data) {
        final movieOrders = data.orders
            .where((order) => order.movieId == movie.id)
            .toList();

        if (movieOrders.any((order) => order.hasActiveAccess)) {
          return _MovieAccessState.active;
        }

        if (movie.isFree && movieOrders.isEmpty) {
          return _MovieAccessState.freeAvailable;
        }

        return _MovieAccessState.paymentRequired;
      },
      orElse: () => movie.isFree
          ? _MovieAccessState.freeAvailable
          : _MovieAccessState.paymentRequired,
    );
  }

  String _watchButtonTitle(_MovieAccessState accessState) {
    return switch (accessState) {
      _MovieAccessState.freeAvailable => 'Watch Free',
      _MovieAccessState.active => 'Watch Now',
      _MovieAccessState.paymentRequired => 'Watch for ${_paidPriceLabel()}',
    };
  }

  String _watchButtonSubtitle(_MovieAccessState accessState) {
    return switch (accessState) {
      _MovieAccessState.freeAvailable => 'Claim free access',
      _MovieAccessState.active => 'In your library',
      _MovieAccessState.paymentRequired =>
        movie.isFree ? 'Free access used' : 'Add to your library',
    };
  }

  String _paidPriceLabel() {
    final price = movie.price;
    if (price <= 0) return movie.priceLabel;

    final decimals = price % 1 == 0 ? 0 : 2;
    return '\$${price.toStringAsFixed(decimals)}';
  }

  List<Movie> _relatedMovies(AsyncValue<HomeData> homeDataState) {
    final selectedGenre = movie.genre.trim().toLowerCase();
    if (selectedGenre.isEmpty) return const [];

    return homeDataState.maybeWhen(
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
