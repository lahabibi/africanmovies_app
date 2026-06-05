import 'package:africanmovies/features/genres/widgets/category_circle_item.dart';
import 'package:africanmovies/features/genres/widgets/genre_filter_bar.dart';
import 'package:africanmovies/features/genres/widgets/genre_movie_grid_card.dart';
import 'package:africanmovies/features/genres/widgets/genre_tab_selector.dart';
import 'package:africanmovies/features/genres/widgets/language_section.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
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
  final List<Movie> movies;

  const _LanguageSectionData({required this.language, required this.movies});
}

enum _GenreSortOption {
  title('Title'),
  newest('Newest'),
  releaseYear('Year'),
  duration('Duration');

  final String label;

  const _GenreSortOption(this.label);
}

class _GenresScreenState extends ConsumerState<GenresScreen> {
  int _selectedTabIndex = 0;
  String? _selectedGenre;
  _GenreSortOption _selectedSort = _GenreSortOption.title;

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.selectedGenre;
  }

  @override
  void didUpdateWidget(covariant GenresScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedGenre != oldWidget.selectedGenre) {
      _selectedTabIndex = 0;
      _selectedGenre = widget.selectedGenre;
    }
  }

  Future<void> _refreshHomeData() async {
    await forceRefreshHomeData(ref);
  }

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
    final movies = _sortGenreMovies(data.moviesByGenre(selectedGenre));

    return _GenresTabContent(
      genres: genres,
      movies: movies,
      selectedGenreIndex: selectedGenreIndex,
      selectedSort: _selectedSort,
      onGenreSelected: (index) {
        setState(() => _selectedGenre = genres[index].label);
      },
      onSortTap: _showSortOptions,
      onMovieTap: _openMovieDetails,
    );
  }

  Widget _buildLanguagesContent(HomeData data) {
    final sections = _languageSections(data);

    if (sections.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: const EmptyState(
          title: 'No languages yet',
          subtitle: 'Languages will appear here when movies are available.',
        ),
      );
    }

    return _LanguagesTabContent(
      sections: sections,
      onMovieTap: _openMovieDetails,
      onSeeAllTap: _openLanguageMovieList,
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

  List<_LanguageSectionData> _languageSections(HomeData data) {
    final groups = <String, List<Movie>>{};
    final labels = <String, String>{};

    for (final movie in data.movies) {
      final language = movie.language.trim();
      if (language.isEmpty) continue;

      final key = language.toLowerCase();
      labels.putIfAbsent(key, () => language);
      groups.putIfAbsent(key, () => []).add(movie);
    }

    final sections = groups.entries.map((entry) {
      final movies = [...entry.value]..sort(_compareMoviesByUploadDate);

      return _LanguageSectionData(
        language: labels[entry.key] ?? entry.key,
        movies: movies,
      );
    }).toList();

    sections.sort(
      (left, right) =>
          left.language.toLowerCase().compareTo(right.language.toLowerCase()),
    );

    return sections;
  }

  int _compareMoviesByUploadDate(Movie left, Movie right) {
    final leftDate = left.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final rightDate =
        right.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);

    return rightDate.compareTo(leftDate);
  }

  List<Movie> _sortGenreMovies(List<Movie> movies) {
    final sortedMovies = [...movies];

    sortedMovies.sort((left, right) {
      return switch (_selectedSort) {
        _GenreSortOption.title => _compareStrings(left.title, right.title),
        _GenreSortOption.newest => _compareMoviesByUploadDate(left, right),
        _GenreSortOption.releaseYear => _compareReleaseYear(left, right),
        _GenreSortOption.duration => right.duration.compareTo(left.duration),
      };
    });

    return sortedMovies;
  }

  int _compareStrings(String left, String right) {
    return left.trim().toLowerCase().compareTo(right.trim().toLowerCase());
  }

  int _compareReleaseYear(Movie left, Movie right) {
    final rightYear = _yearFor(right);
    final leftYear = _yearFor(left);

    final yearCompare = rightYear.compareTo(leftYear);
    if (yearCompare != 0) return yearCompare;

    return _compareStrings(left.title, right.title);
  }

  int _yearFor(Movie movie) {
    final releaseYear = int.tryParse(movie.releaseYear?.trim() ?? '');
    if (releaseYear != null) return releaseYear;

    return movie.uploadDate?.year ?? 0;
  }

  Future<void> _showSortOptions() async {
    final selectedSort = await showModalBottomSheet<_GenreSortOption>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, bottomInset + 12.h),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 8.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        color: AppColors.heroButton,
                        size: 22.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._GenreSortOption.values.map((option) {
                  return _SortOptionTile(
                    option: option,
                    selected: option == _selectedSort,
                    onTap: () => Navigator.pop(sheetContext, option),
                  );
                }),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );

    if (selectedSort == null || selectedSort == _selectedSort) return;

    setState(() => _selectedSort = selectedSort);
  }

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  void _openLanguageMovieList(_LanguageSectionData section) {
    if (section.movies.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MovieListScreen(title: section.language, movies: section.movies),
      ),
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
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: _refreshHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                      homeData.when(
                        data: _buildLanguagesContent,
                        error: (error, _) => _GenresErrorView(
                          message: error.toString(),
                          onRetry: () => ref.invalidate(homeDataProvider),
                        ),
                        loading: _GenresLoadingView.new,
                      ),
                  ],
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
}

class _GenresTabContent extends StatelessWidget {
  final List<_CategoryItem> genres;
  final List<Movie> movies;
  final int selectedGenreIndex;
  final _GenreSortOption selectedSort;
  final ValueChanged<int> onGenreSelected;
  final VoidCallback onSortTap;
  final ValueChanged<Movie> onMovieTap;

  const _GenresTabContent({
    required this.genres,
    required this.selectedGenreIndex,
    required this.selectedSort,
    required this.onGenreSelected,
    required this.onSortTap,
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
            separatorBuilder: (context, index) => SizedBox(width: 14.w),
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
          sortValue: selectedSort.label,
          onSortTap: onSortTap,
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

class _SortOptionTile extends StatelessWidget {
  final _GenreSortOption option;
  final bool selected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    return switch (option) {
      _GenreSortOption.title => Icons.sort_by_alpha_rounded,
      _GenreSortOption.newest => Icons.schedule_rounded,
      _GenreSortOption.releaseYear => Icons.calendar_month_outlined,
      _GenreSortOption.duration => Icons.timer_outlined,
    };
  }

  String get _subtitle {
    return switch (option) {
      _GenreSortOption.title => 'A to Z',
      _GenreSortOption.newest => 'Recently uploaded first',
      _GenreSortOption.releaseYear => 'Latest release year first',
      _GenreSortOption.duration => 'Longest movies first',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.heroButton.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: selected
                        ? AppColors.heroButton.withValues(alpha: 0.48)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Icon(
                  _icon,
                  color: selected
                      ? AppColors.heroButton
                      : AppColors.textSecondary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.heroButton,
                  size: 20.sp,
                ),
            ],
          ),
        ),
      ),
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
  final ValueChanged<Movie> onMovieTap;
  final ValueChanged<_LanguageSectionData> onSeeAllTap;

  const _LanguagesTabContent({
    required this.sections,
    required this.onMovieTap,
    required this.onSeeAllTap,
  });

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
            movies: section.movies,
            onMovieTap: onMovieTap,
            onSeeAllTap: () => onSeeAllTap(section),
          ),
        );
      }),
    );
  }
}
