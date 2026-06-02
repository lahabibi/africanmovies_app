import 'package:africanmovies/features/genres/widgets/category_circle_item.dart';
import 'package:africanmovies/features/genres/widgets/genre_filter_bar.dart';
import 'package:africanmovies/features/genres/widgets/genre_movie_grid_card.dart';
import 'package:africanmovies/features/genres/widgets/genre_tab_selector.dart';
import 'package:africanmovies/features/genres/widgets/language_section.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/empty_state.dart';
import '../home/widgets/home_header.dart';

class GenresScreen extends ConsumerStatefulWidget {
  final String? selectedGenre;

  const GenresScreen({super.key, this.selectedGenre});

  @override
  ConsumerState<GenresScreen> createState() => _GenresScreenState();
}

class _CategoryItem {
  final String label;
  final String image;

  const _CategoryItem({required this.label, required this.image});
}

class _LanguageSectionData {
  final String language;
  final int movieCount;
  final List<LanguageMovieItem> movies;

  const _LanguageSectionData({
    required this.language,
    required this.movieCount,
    required this.movies,
  });
}

class _GenresScreenState extends ConsumerState<GenresScreen> {
  int _selectedTabIndex = 0;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.selectedGenre;
  }

  @override
  void didUpdateWidget(covariant GenresScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedGenre != oldWidget.selectedGenre &&
        widget.selectedGenre != null) {
      _selectedTabIndex = 0;
      _selectedGenre = widget.selectedGenre;
    }
  }

  static const _languageSections = [
    _LanguageSectionData(
      language: 'English',
      movieCount: 128,
      movies: [
        LanguageMovieItem(
          image: AppAssets.poster1,
          year: '2023',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster2,
          year: '2024',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster3,
          year: '2023',
          genre: 'Romance',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster4,
          year: '2018',
          genre: 'Comedy',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster5,
          year: '2018',
          genre: 'Comedy',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster6,
          year: '2018',
          genre: 'Drama',
          ageRating: '16+',
        ),
      ],
    ),
    _LanguageSectionData(
      language: 'Yoruba',
      movieCount: 96,
      movies: [
        LanguageMovieItem(
          image: AppAssets.poster7,
          year: '2024',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster8,
          year: '2023',
          genre: 'Romance',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster9,
          year: '2024',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster10,
          year: '2023',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster11,
          year: '2023',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster12,
          year: '2023',
          genre: 'Comedy',
          ageRating: '16+',
        ),
      ],
    ),
    _LanguageSectionData(
      language: 'Igbo',
      movieCount: 88,
      movies: [
        LanguageMovieItem(
          image: AppAssets.poster13,
          year: '2023',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster19,
          year: '2024',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster15,
          year: '2024',
          genre: 'Romance',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster16,
          year: '2024',
          genre: 'Romance',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster17,
          year: '2024',
          genre: 'Romance',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster18,
          year: '2024',
          genre: 'Romance',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster14,
          year: '2024',
          genre: 'Romance',
          ageRating: '16+',
        ),
      ],
    ),
    _LanguageSectionData(
      language: 'Twi',
      movieCount: 12,
      movies: [
        LanguageMovieItem(
          image: AppAssets.poster20,
          year: '2023',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster6,
          year: '2024',
          genre: 'Drama',
          ageRating: '16+',
        ),
        LanguageMovieItem(
          image: AppAssets.poster12,
          year: '2024',
          genre: 'Romance',
          ageRating: '16+',
        ),
      ],
    ),
  ];

  Widget _buildGenresContent(HomeData data) {
    final genres = _genreItems(data);
    if (genres.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: const EmptyState(
          title: 'No genres yet',
          subtitle: 'Genres will appear here when movies are available.',
        ),
      );
    }

    final selectedGenreIndex = _selectedGenreIndexFor(genres);
    final selectedGenre = genres[selectedGenreIndex].label;
    final movies = data.moviesByGenre(selectedGenre);

    return _GenresTabContent(
      genres: genres,
      movies: movies,
      selectedGenreIndex: selectedGenreIndex,
      onGenreSelected: (index) {
        setState(() => _selectedGenre = genres[index].label);
      },
      onMovieTap: _openMovieDetails,
    );
  }

  List<_CategoryItem> _genreItems(HomeData data) {
    final backendGenres = data.genres
        .where((genre) => genre.name.isNotEmpty)
        .map(
          (genre) => _CategoryItem(
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
        .map((genre) => _CategoryItem(label: genre, image: AppAssets.genre))
        .toList();
  }

  int _selectedGenreIndexFor(List<_CategoryItem> genres) {
    final selectedGenre = _selectedGenre?.trim().toLowerCase();
    if (selectedGenre != null && selectedGenre.isNotEmpty) {
      final selectedIndex = genres.indexWhere(
        (genre) => genre.label.trim().toLowerCase() == selectedGenre,
      );
      if (selectedIndex != -1) return selectedIndex;
    }

    return 0;
  }

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
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
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GenreTabSelector(
                    selectedIndex: _selectedTabIndex,
                    onChanged: (index) {
                      setState(() => _selectedTabIndex = index);
                    },
                  ),
                  SizedBox(height: 12.h),

                  if (_selectedTabIndex == 0)
                    homeData.when(
                      data: _buildGenresContent,
                      error: (error, _) => _GenresErrorView(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(homeDataProvider),
                      ),
                      loading: _GenresLoadingView.new,
                    )
                  else
                    const _LanguagesTabContent(sections: _languageSections),
                ],
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
}

class _GenresTabContent extends StatelessWidget {
  final List<_CategoryItem> genres;
  final List<Movie> movies;
  final int selectedGenreIndex;
  final ValueChanged<int> onGenreSelected;
  final ValueChanged<Movie> onMovieTap;

  const _GenresTabContent({
    required this.genres,
    required this.selectedGenreIndex,
    required this.onGenreSelected,
    required this.movies,
    required this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    final gridSpacing = Responsive.gridSpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 82.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (_, _) => SizedBox(width: 14.w),
            itemBuilder: (_, index) {
              final genre = genres[index];

              return CategoryCircleItem(
                label: genre.label,
                image: genre.image,
                selected: selectedGenreIndex == index,
                onTap: () => onGenreSelected(index),
              );
            },
          ),
        ),
        SizedBox(height: 4.h),

        GenreFilterBar(
          title: genres[selectedGenreIndex].label,
          movieCount: movies.length,
          onSortTap: () {},
        ),
        SizedBox(height: 8.h),

        if (movies.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: EmptyState(
                title: 'No movies yet',
                subtitle:
                    'There are no movies available in this genre right now.',
              ),
            ),
          )
        else
          GridView.builder(
            itemCount: movies.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.posterGridColumns(context),
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: Responsive.isTablet(context) ? 14 : 10.h,
              childAspectRatio: Responsive.compactPosterGridAspectRatio(
                context,
              ),
            ),
            itemBuilder: (_, index) {
              final movie = movies[index];

              return GenreMovieGridCard(
                image: movie.displayPosterUrl,
                year: movie.yearLabel,
                duration: movie.durationLabel,
                ageRating: movie.ageRatingLabel,
                onTap: () => onMovieTap(movie),
              );
            },
          ),
      ],
    );
  }
}

class _GenresLoadingView extends StatelessWidget {
  const _GenresLoadingView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260.h,
      child: Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _GenresErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GenresErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: Column(
        children: [
          EmptyState(title: 'Unable to load genres', subtitle: message),
          SizedBox(height: 12.h),
          TextButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _LanguagesTabContent extends StatelessWidget {
  final List<_LanguageSectionData> sections;

  const _LanguagesTabContent({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(sections.length, (index) {
        final section = sections[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == sections.length - 1 ? 0 : 8.h,
          ),
          child: LanguageSection(
            language: section.language,
            movieCount: section.movieCount,
            movies: section.movies,
          ),
        );
      }),
    );
  }
}
