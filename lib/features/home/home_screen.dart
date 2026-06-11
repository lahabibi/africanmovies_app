import 'dart:async';

import 'package:africanmovies/core/network/api_exception.dart';
import 'package:africanmovies/features/home/widgets/continue_watching_card.dart';
import 'package:africanmovies/features/home/widgets/genre_circle_item.dart';
import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/player/application/player_providers.dart';
import 'package:africanmovies/features/player/movie_player_screen.dart';
import 'package:africanmovies/features/player/trailer_player_screen.dart';
import 'package:africanmovies/shared/widgets/app_image.dart';
import 'package:africanmovies/shared/widgets/section_movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/hero_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onGenreSelected;
  final VoidCallback? onGenresRequested;

  const HomeScreen({super.key, this.onGenreSelected, this.onGenresRequested});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _heroController = PageController();
  int _activeHeroIndex = 0;
  int _heroItemCount = 1;
  Timer? _heroTimer;
  String? _openingContinueWatchingOrderId;

  @override
  void initState() {
    super.initState();

    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_heroController.hasClients || _heroItemCount <= 1) return;

      final nextIndex = (_activeHeroIndex + 1) % _heroItemCount;

      _heroController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _refreshHomeData() async {
    await forceRefreshHomeData(ref);
  }

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  void _openMovieList(String title, List<Movie> movies) {
    if (movies.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieListScreen(title: title, movies: movies),
      ),
    );
  }

  void _openTrailer(Movie movie) {
    final trailerUrl = movie.trailerUrl.trim();

    if (trailerUrl.isEmpty) {
      _showMessage('Trailer unavailable');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrailerPlayerScreen(title: movie.title, videoUrl: trailerUrl),
      ),
    );
  }

  Future<void> _openContinueWatching(HomeOrder order) async {
    final movie = order.movie;
    if (movie == null || _openingContinueWatchingOrderId != null) return;

    final openingId = order.id.isNotEmpty ? order.id : movie.id;
    setState(() => _openingContinueWatchingOrderId = openingId);

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
      if (mounted) {
        setState(() => _openingContinueWatchingOrderId = null);
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

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);
    final homeData = ref.watch(homeDataProvider);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: homeData.when(
              data: _buildHomeContent,
              error: (error, _) => _HomeErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(homeDataProvider),
              ),
              loading: _HomeLoadingView.new,
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

  Widget _buildHomeContent(HomeData data) {
    final heroMovies = data.bannerMovies;
    final latestMovies = data.latestUploadedMovies;
    final genreItems = _genreItems(data);
    final genreMovieSections = _genreMovieSections(data, genreItems);
    final continueWatchingOrders = data.continueWatchingOrders;
    final hasContinueWatching = continueWatchingOrders.isNotEmpty;

    if (data.movies.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: _refreshHomeData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: const _HomeEmptyView(),
              ),
            );
          },
        ),
      );
    }

    _heroItemCount = heroMovies.length;
    if (_activeHeroIndex >= _heroItemCount) _activeHeroIndex = 0;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _refreshHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heroMovies.isNotEmpty) ...[
              SizedBox(
                height: Responsive.heroHeight(context),
                child: PageView.builder(
                  controller: _heroController,
                  itemCount: heroMovies.length,
                  onPageChanged: (index) {
                    setState(() => _activeHeroIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final movie = heroMovies[index];

                    return HeroBanner(
                      type: HeroBannerType.image,
                      image: movie.displayBannerUrl,
                      title: movie.title,
                      description: movie.description,
                      year: movie.yearLabel,
                      genre: movie.genre,
                      releaseType: movie.releaseType,
                      duration: movie.durationLabel,
                      ageRating: movie.ageRatingLabel,
                      onWatchNowTap: () => _openMovieDetails(movie),
                      onTrailerTap: () => _openTrailer(movie),
                    );
                  },
                ),
              ),

              SizedBox(height: 10.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(heroMovies.length, (index) {
                  final selected = index == _activeHeroIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.heroButton
                          : Colors.white.withValues(alpha: 0.22),
                    ),
                  );
                }),
              ),
            ],

            if (hasContinueWatching) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              _ContinueWatchingSection(
                orders: continueWatchingOrders,
                openingOrderId: _openingContinueWatchingOrderId,
                onOrderTap: _openContinueWatching,
                onSeeAllTap: continueWatchingOrders.length > 2
                    ? () {
                        _openMovieList(
                          'Continue Watching',
                          data.continueWatchingMovies,
                        );
                      }
                    : null,
              ),
            ],

            if (!hasContinueWatching) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              _NewReleasesSection(
                movies: latestMovies,
                onSeeAllTap: () => _openMovieList('New Releases', latestMovies),
                onMovieTap: _openMovieDetails,
              ),
            ],

            if (genreItems.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              _GenresStripSection(
                items: genreItems,
                onSeeAllTap: widget.onGenresRequested,
                onGenreSelected: widget.onGenreSelected,
              ),
            ],

            if (hasContinueWatching) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              _NewReleasesSection(
                movies: latestMovies,
                onSeeAllTap: () => _openMovieList('New Releases', latestMovies),
                onMovieTap: _openMovieDetails,
              ),
            ],

            for (final section in genreMovieSections) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              SectionHeader(
                title: section.genre,
                actionText: 'See All »',
                onActionTap: () {
                  _openMovieList(section.genre, section.movies);
                },
              ),
              SizedBox(height: 10.h),
              _MovieRow(movies: section.movies, onMovieTap: _openMovieDetails),
            ],
          ],
        ),
      ),
    );
  }

  List<_HomeGenreItem> _genreItems(HomeData data) {
    final backendGenres = data.genres
        .where((genre) => genre.name.isNotEmpty)
        .map(
          (genre) => _HomeGenreItem(
            label: genre.name,
            image: genre.iconUrl.isNotEmpty ? genre.iconUrl : AppAssets.genre,
          ),
        )
        .toList();

    if (backendGenres.isNotEmpty) return backendGenres;

    return data.movies
        .map((movie) => movie.genre)
        .where((genre) => genre.isNotEmpty)
        .toSet()
        .map((genre) => _HomeGenreItem(label: genre, image: AppAssets.genre))
        .toList();
  }

  List<_HomeGenreMovieSection> _genreMovieSections(
    HomeData data,
    List<_HomeGenreItem> genreItems,
  ) {
    final sections = <_HomeGenreMovieSection>[];
    final seenGenres = <String>{};

    void addSection(String genre) {
      final normalizedGenre = genre.trim().toLowerCase();
      if (normalizedGenre.isEmpty || seenGenres.contains(normalizedGenre)) {
        return;
      }

      seenGenres.add(normalizedGenre);
      final movies = data.moviesByGenre(genre);
      if (movies.isEmpty) return;

      sections.add(_HomeGenreMovieSection(genre: genre, movies: movies));
    }

    for (final genre in genreItems) {
      addSection(genre.label);
    }

    for (final movie in data.movies) {
      addSection(movie.genre);
    }

    return sections;
  }
}

class _HomeGenreItem {
  final String label;
  final String image;

  const _HomeGenreItem({required this.label, required this.image});
}

class _HomeGenreMovieSection {
  final String genre;
  final List<Movie> movies;

  const _HomeGenreMovieSection({required this.genre, required this.movies});
}

class _NewReleasesSection extends StatelessWidget {
  final List<Movie> movies;
  final VoidCallback onSeeAllTap;
  final ValueChanged<Movie> onMovieTap;

  const _NewReleasesSection({
    required this.movies,
    required this.onSeeAllTap,
    required this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'New Releases',
          actionText: 'See All »',
          onActionTap: onSeeAllTap,
        ),
        SizedBox(height: 10.h),
        _MovieRow(movies: movies, onMovieTap: onMovieTap),
      ],
    );
  }
}

class _GenresStripSection extends StatelessWidget {
  final List<_HomeGenreItem> items;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<String>? onGenreSelected;

  const _GenresStripSection({
    required this.items,
    this.onSeeAllTap,
    this.onGenreSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Genres',
          actionText: 'See All »',
          onActionTap: onSeeAllTap,
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 70.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(width: 18.w),
            itemBuilder: (_, index) {
              final genre = items[index];

              return GenreCircleItem(
                label: genre.label,
                image: genre.image,
                onTap: () => onGenreSelected?.call(genre.label),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  final List<HomeOrder> orders;
  final String? openingOrderId;
  final ValueChanged<HomeOrder> onOrderTap;
  final VoidCallback? onSeeAllTap;

  const _ContinueWatchingSection({
    required this.orders,
    required this.openingOrderId,
    required this.onOrderTap,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final useCompactLayout = orders.length <= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Continue Watching',
          actionText: onSeeAllTap == null ? null : 'See All »',
          onActionTap: onSeeAllTap,
        ),
        SizedBox(height: 8.h),
        if (useCompactLayout)
          Column(
            children: [
              for (var index = 0; index < orders.length; index++) ...[
                _CompactContinueWatchingCard(
                  order: orders[index],
                  isLoading: _isOpening(orders[index]),
                  onTap: () => onOrderTap(orders[index]),
                ),
                if (index != orders.length - 1) SizedBox(height: 8.h),
              ],
            ],
          )
        else
          SizedBox(
            height: 136.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: orders.length,
              separatorBuilder: (_, _) => SizedBox(width: 5.w),
              itemBuilder: (_, index) {
                final order = orders[index];
                final movie = order.movie;
                if (movie == null) return const SizedBox.shrink();

                return ContinueWatchingCard(
                  image: movie.displayPosterUrl,
                  timeLeft: _formatResumePosition(order.currentTime),
                  progress: order.progress,
                  onTap: () => onOrderTap(order),
                );
              },
            ),
          ),
      ],
    );
  }

  bool _isOpening(HomeOrder order) {
    final movie = order.movie;
    if (movie == null) return false;

    final orderId = order.id.isNotEmpty ? order.id : movie.id;
    return openingOrderId == orderId;
  }
}

class _CompactContinueWatchingCard extends StatelessWidget {
  final HomeOrder order;
  final bool isLoading;
  final VoidCallback onTap;

  const _CompactContinueWatchingCard({
    required this.order,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final movie = order.movie!;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 92.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 76.w,
              height: double.infinity,
              child: AppImage(source: movie.displayPosterUrl),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(11.w, 9.h, 9.w, 9.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _movieMeta(movie),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: order.progress,
                        minHeight: 3.h,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.heroButton,
                        ),
                      ),
                    ),
                    SizedBox(height: 7.h),
                    Row(
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.heroButton,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.heroButton.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 10.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: isLoading
                              ? Padding(
                                  padding: EdgeInsets.all(5.w),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 17.sp,
                                ),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            'Resume at ${_formatResumePosition(order.currentTime)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieRow extends StatelessWidget {
  final List<Movie> movies;
  final ValueChanged<Movie> onMovieTap;

  const _MovieRow({required this.movies, required this.onMovieTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, _) => SizedBox(width: 5.w),
        itemBuilder: (_, index) {
          final movie = movies[index];

          return SectionMovieCard(
            image: movie.displayPosterUrl,
            showFreeBadge: movie.isFree,
            onTap: () => onMovieTap(movie),
          );
        },
      ),
    );
  }
}

String _movieMeta(Movie movie) {
  final items = [
    if (movie.duration > 0) movie.durationLabel,
    if (movie.genre.isNotEmpty) movie.genre,
  ];

  return items.join(' / ');
}

String _formatResumePosition(double seconds) {
  final totalSeconds = seconds.round();
  if (totalSeconds <= 0) return '0:00';

  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final remainingSeconds = duration.inSeconds.remainder(60);
  final paddedSeconds = remainingSeconds.toString().padLeft(2, '0');

  if (hours > 0) {
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    return '$hours:$paddedMinutes:$paddedSeconds';
  }

  return '$minutes:$paddedSeconds';
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 30.w,
        height: 30.w,
        child: const CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textSecondary,
              size: 42.sp,
            ),
            SizedBox(height: 14.h),
            Text(
              'Unable to load movies',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
            SizedBox(height: 18.h),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEmptyView extends StatelessWidget {
  const _HomeEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No movies available yet',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
