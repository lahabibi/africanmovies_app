import 'dart:async';
import 'package:africanmovies/features/home/widgets/continue_watching_card.dart';
import 'package:africanmovies/features/home/widgets/genre_circle_item.dart';
import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/shared/widgets/section_movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/hero_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _GenreItem {
  final String label;
  final String image;

  const _GenreItem({
    required this.label,
    required this.image,
  });
}


class _HeroMovie {
  final String image;
  final String title;
  final String releaseType;
  final String year;
  final String genre;
  final String description;
  final String duration;
  final String ageRating;

  const _HeroMovie({
    required this.image,
    required this.title,
    required this.description,
    required this.year,
    required this.genre,
    required this.releaseType,
    required this.duration,
    required this.ageRating,
  });
}

class _ContinueWatchingMovie {
  final String image;
  final String timeLeft;
  final double progress;
  final String? expiryText;

  const _ContinueWatchingMovie({
    required this.image,
    required this.timeLeft,
    required this.progress,
    this.expiryText,
  });
}

class _SectionMovie {
  final String image;

  const _SectionMovie({
    required this.image,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  int _activeHeroIndex = 0;
  Timer? _heroTimer;

  static const _posters = [
    _SectionMovie(image: AppAssets.poster6),
    _SectionMovie(image: AppAssets.poster7),
    _SectionMovie(image: AppAssets.poster8),
    _SectionMovie(image: AppAssets.poster15),
    _SectionMovie(image: AppAssets.poster11),
    _SectionMovie(image: AppAssets.poster16),
  ];

  static const _posters2 = [
    AppAssets.poster12,
    AppAssets.poster13,
    AppAssets.poster10,
    AppAssets.poster14,
    AppAssets.poster9,
    AppAssets.poster5,
  ];

  static const _heroMovies = [
    _HeroMovie(
      image: AppAssets.banner5,
      title: "True Love",
      description: 'A POWERFUL STORY OF FAMILY,\nCOURAGE AND SURVIVAL',
      year: '2025',
      genre: 'Drama',
      releaseType: 'Action',
      duration: '2h 04m',
      ageRating: '16+',
    ),
    _HeroMovie(
      image: AppAssets.banner3,
      title: "Friends betrayal",
      description: 'LOVE, BETRAYAL AND POWER\nCOLLIDE IN LAGOS',
      year: '2024',
      genre: 'Romance',
      releaseType: 'Drama',
      duration: '1h 58m',
      ageRating: '13+',
    ),
    _HeroMovie(
      image: AppAssets.banner1,
      title: "The love story",
      description: 'CLASSISM, FEAR, CONTROL,\n"MONEY NO FIT BUY HAPPINESS"',
      year: '2024',
      genre: 'Drama',
      releaseType: 'Thriller',
      duration: '2h 15m',
      ageRating: '16+',
    ),
    _HeroMovie(
      image: AppAssets.banner2,
      title: "Family Affairs",
      description: 'A POWERFUL STORY OF FAMILY,\nCOURAGE AND SURVIVAL',
      year: '2023',
      genre: 'Drama',
      releaseType: 'Action',
      duration: '2h 04m',
      ageRating: '16+',
    ),
  ];

  static const _continueWatchingMovies = [
    _ContinueWatchingMovie(
      image: AppAssets.poster1,
      timeLeft: '18 min left',
      progress: 0.72,

    ),
    _ContinueWatchingMovie(
      image: AppAssets.poster11,
      timeLeft: '1h 3 min left',
      progress: 0.22,
      expiryText: '12h left',
    ),
    _ContinueWatchingMovie(
      image: AppAssets.poster2,
      timeLeft: '42 min left',
      progress: 0.34,
    ),
    _ContinueWatchingMovie(
      image: AppAssets.poster3,
      timeLeft: '9 min left',
      progress: 0.88,
      expiryText: '3 days left',
    ),
    _ContinueWatchingMovie(
      image: AppAssets.poster4,
      timeLeft: '1h 12m left',
      progress: 0.21,
    ),
    _ContinueWatchingMovie(
      image: AppAssets.poster5,
      timeLeft: '27 min left',
      progress: 0.56,
    ),
  ];

  static const _genres = [
  _GenreItem(label: 'Action', image: AppAssets.genreAction),
  _GenreItem(label: 'Comedy', image: AppAssets.genreComedy),
  _GenreItem(label: 'Drama', image: AppAssets.genreDrama),
  _GenreItem(label: 'Romance', image: AppAssets.genreRomance),
  _GenreItem(label: 'Thriller', image: AppAssets.genreThriller),
  _GenreItem(label: 'Crime', image: AppAssets.genreCrime),
    _GenreItem(label: 'Horror', image: AppAssets.genreHorror),
  ];

  @override
  void initState() {
    super.initState();

    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_heroController.hasClients) return;

      final nextIndex = (_activeHeroIndex + 1) % _heroMovies.length;

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 48.h),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 210.h,
                    child: PageView.builder(
                      controller: _heroController,
                      itemCount: _heroMovies.length,
                      onPageChanged: (index) {
                        setState(() => _activeHeroIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final movie = _heroMovies[index];

                        return HeroBanner(
                          type: HeroBannerType.image,
                          image: movie.image,
                          title: movie.title,
                          description: movie.description,
                          year: movie.year,
                          genre: movie.genre,
                          releaseType: movie.releaseType,
                          duration: movie.duration,
                          ageRating: movie.ageRating,
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 10.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_heroMovies.length, (index) {
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
                      itemCount: _continueWatchingMovies.length,
                      separatorBuilder: (_, __) => SizedBox(width: 5.w),
                      itemBuilder: (_, index) {
                        final movie = _continueWatchingMovies[index];

                        return ContinueWatchingCard(
                          image: movie.image,
                          timeLeft: movie.timeLeft,
                          progress: movie.progress,
                          expiryText: movie.expiryText,
                        );
                      },
                    ),
                  ),

                  SizedBox(height: AppSpacing.sectionXxsGap),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MovieListScreen()
                        ),
                      );
                    },
                    child: const SectionHeader(
                      title: 'Trending Movies',
                      actionText: 'See All »',
                    ),
                  ),

                  SizedBox(height: 10.h),

                  SizedBox(
                    height: 168.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _posters.length,
                      separatorBuilder: (_, __) => SizedBox(width: 5.w),
                      itemBuilder: (_, index) {
                        final movie = _posters[index];
                        return SectionMovieCard(
                          image: movie.image,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MovieDetailsScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  SizedBox(height: AppSpacing.sectionXxsGap),

                  const SectionHeader(
                    title: 'Genres',
                    actionText: 'See All »',
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 82.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _genres.length,
                      separatorBuilder: (_, __) => SizedBox(width: 18.w),
                      itemBuilder: (_, index) {
                        final genre = _genres[index];

                        return GenreCircleItem(
                          label: genre.label,
                          image: genre.image,
                          onTap: () {},
                        );
                      },
                    ),
                  ),

                  SizedBox(height: AppSpacing.sectionXxsGap),

                  const SectionHeader(
                    title: 'comedy',
                    actionText: 'See All »',
                  ),

                  SizedBox(height: 10.h),

                  SizedBox(
                    height: 168.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _posters2.length,
                      separatorBuilder: (_, __) => SizedBox(width: 5.w),
                      itemBuilder: (_, index) {
                        return SectionMovieCard(
                          image: _posters2[index],
                        );
                      },
                    ),
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
              height: 48.h,
              child: const HomeHeader(),
            ),
          ),
        ],
      ),
    );
  }
}
