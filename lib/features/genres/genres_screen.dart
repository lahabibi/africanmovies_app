import 'package:africanmovies/features/genres/widgets/category_circle_item.dart';
import 'package:africanmovies/features/genres/widgets/genre_filter_bar.dart';
import 'package:africanmovies/features/genres/widgets/genre_movie_grid_card.dart';
import 'package:africanmovies/features/genres/widgets/genre_tab_selector.dart';
import 'package:africanmovies/features/genres/widgets/language_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/empty_state.dart';
import '../home/widgets/home_header.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _CategoryItem {
  final String label;
  final String image;

  const _CategoryItem({required this.label, required this.image});
}

class _GenreMovie {
  final String image;
  final String year;
  final String genre;
  final String duration;
  final String ageRating;

  const _GenreMovie({
    required this.image,
    required this.year,
    required this.genre,
    required this.duration,
    required this.ageRating,
  });
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

class _GenresScreenState extends State<GenresScreen> {
  int _selectedTabIndex = 0;
  int _selectedGenreIndex = 0;

  List<_GenreMovie> get _filteredGenreMovies {
    final selectedGenre = _genres[_selectedGenreIndex].label;

    return _genreMovies.where((movie) {
      return movie.genre == selectedGenre;
    }).toList();
  }

  static const _genres = [
    _CategoryItem(label: 'Action', image: AppAssets.genreAction),
    _CategoryItem(label: 'Comedy', image: AppAssets.genreComedy),
    _CategoryItem(label: 'Drama', image: AppAssets.genreDrama),
    _CategoryItem(label: 'Romance', image: AppAssets.genreRomance),
    _CategoryItem(label: 'Thriller', image: AppAssets.genreThriller),
    _CategoryItem(label: 'Crime', image: AppAssets.genreCrime),
    _CategoryItem(label: 'Horror', image: AppAssets.genreHorror),
  ];

  static const _genreMovies = [
    _GenreMovie(
      image: AppAssets.poster1,
      year: '2024',
      genre: 'Action',
      duration: '2h 15m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster2,
      year: '2022',
      genre: 'Action',
      duration: '2h 55m',
      ageRating: '17+',
    ),
    _GenreMovie(
      image: AppAssets.poster3,
      year: '2025',
      genre: 'Action',
      duration: '2h 15m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster4,
      year: '2024',
      genre: 'Action',
      duration: '2h 15m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster5,
      year: '2023',
      genre: 'Action',
      duration: '1h 58m',
      ageRating: '13+',
    ),
    _GenreMovie(
      image: AppAssets.poster6,
      year: '2025',
      duration: '2h 04m',
      genre: 'Action',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster7,
      year: '2022',
      genre: 'Action',
      duration: '1h 45m',
      ageRating: '18+',
    ),
    _GenreMovie(
      image: AppAssets.poster8,
      year: '2024',
      genre: 'Action',
      duration: '2h 10m',
      ageRating: '13+',
    ),
    _GenreMovie(
      image: AppAssets.poster9,
      year: '2023',
      genre: 'Action',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster20,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster19,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster18,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster17,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster16,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster15,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster14,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster13,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster12,
      year: '2023',
      genre: 'Comedy',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster11,
      year: '2023',
      genre: 'Drama',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster10,
      year: '2023',
      genre: 'Drama',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster9,
      year: '2023',
      genre: 'Drama',
      duration: '1h 52m',
      ageRating: '16+',
    ),
    _GenreMovie(
      image: AppAssets.poster8,
      year: '2023',
      genre: 'Drama',
      duration: '1h 52m',
      ageRating: '16+',
    ),
  ];


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
                  GenreTabSelector(
                    selectedIndex: _selectedTabIndex,
                    onChanged: (index) {
                      setState(() => _selectedTabIndex = index);
                    },
                  ),
                  SizedBox(height: 12.h),

                  if (_selectedTabIndex == 0)
                    _GenresTabContent(
                      genres: _genres,
                      movies: _filteredGenreMovies,
                      selectedGenreIndex: _selectedGenreIndex,
                      onGenreSelected: (index) {
                        setState(() => _selectedGenreIndex = index);
                      },
                    )
                  else
                    const _LanguagesTabContent(
                      sections: _languageSections,
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: 48.h, child: const HomeHeader()),
          ),
        ],
      ),
    );
  }
}

class _GenresTabContent extends StatelessWidget {
  final List<_CategoryItem> genres;
  final List<_GenreMovie> movies;
  final int selectedGenreIndex;
  final ValueChanged<int> onGenreSelected;

  const _GenresTabContent({
    required this.genres,
    required this.selectedGenreIndex,
    required this.onGenreSelected,
    required this.movies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 82.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (_, __) => SizedBox(width: 14.w),
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

        if(movies.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: EmptyState(
                title: 'No movies yet',
                subtitle: 'There are no movies available in this genre right now.',
              ),
            ),
          )
        else
        GridView.builder(
          itemCount: movies.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 0.62,
          ),
          itemBuilder: (_, index) {
            final movie = movies[index];

            return GenreMovieGridCard(
              image: movie.image,
              year: movie.year,
              duration: movie.duration,
              ageRating: movie.ageRating,
              onTap: () {},
            );
          },
        ),
      ],
    );
  }
}

class _LanguagesTabContent extends StatelessWidget {
  final List<_LanguageSectionData> sections;

  const _LanguagesTabContent({
    required this.sections,
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
            movieCount: section.movieCount,
            movies: section.movies,
          ),
        );
      }),
    );
  }
}
