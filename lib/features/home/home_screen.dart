import 'dart:async';

import 'package:africanmovies/features/home/widgets/continue_watching_card.dart';
import 'package:africanmovies/features/home/widgets/genre_circle_item.dart';
import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/shared/widgets/section_movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/hero_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _heroController = PageController();
  int _activeHeroIndex = 0;
  int _heroItemCount = 1;
  Timer? _heroTimer;

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
    ref.invalidate(homeDataProvider);
    await ref.read(homeDataProvider.future);
  }

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MovieDetailsScreen()),
    );
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
    final genreLabels = genreItems.map((genre) => genre.label).toList();
    final featuredGenre = _featuredGenre(genreLabels);
    final featuredGenreMovies = featuredGenre == null
        ? <Movie>[]
        : data.moviesByGenre(featuredGenre).take(12).toList();
    final continueWatchingMovies = data.continueWatchingMovies;

    if (data.movies.isEmpty) return const _HomeEmptyView();

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

            if (continueWatchingMovies.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              const SectionHeader(
                title: 'Continue Watching',
                actionText: 'See All »',
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 136.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: continueWatchingMovies.length,
                  separatorBuilder: (_, _) => SizedBox(width: 5.w),
                  itemBuilder: (_, index) {
                    final movie = continueWatchingMovies[index];

                    return ContinueWatchingCard(
                      image: movie.displayPosterUrl,
                      timeLeft: 'Resume',
                      progress: 0.34,
                    );
                  },
                ),
              ),
            ],

            SizedBox(height: AppSpacing.sectionXxsGap),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MovieListScreen()),
                );
              },
              child: const SectionHeader(
                title: 'New Releases',
                actionText: 'See All »',
              ),
            ),

            SizedBox(height: 10.h),

            _MovieRow(movies: latestMovies, onMovieTap: _openMovieDetails),

            if (genreItems.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              const SectionHeader(title: 'Genres', actionText: 'See All »'),
              SizedBox(height: 10.h),
              SizedBox(
                height: 82.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: genreItems.length,
                  separatorBuilder: (_, _) => SizedBox(width: 18.w),
                  itemBuilder: (_, index) {
                    final genre = genreItems[index];

                    return GenreCircleItem(
                      label: genre.label,
                      image: genre.image,
                      onTap: () {},
                    );
                  },
                ),
              ),
            ],

            if (featuredGenre != null && featuredGenreMovies.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sectionXxsGap),
              SectionHeader(title: featuredGenre, actionText: 'See All »'),
              SizedBox(height: 10.h),
              _MovieRow(
                movies: featuredGenreMovies,
                onMovieTap: _openMovieDetails,
              ),
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

  String? _featuredGenre(List<String> genres) {
    if (genres.isEmpty) return null;

    for (final genre in genres) {
      if (genre.toLowerCase() == 'comedy') return genre;
    }

    return genres.first;
  }
}

class _HomeGenreItem {
  final String label;
  final String image;

  const _HomeGenreItem({required this.label, required this.image});
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
            onTap: () => onMovieTap(movie),
          );
        },
      ),
    );
  }
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
