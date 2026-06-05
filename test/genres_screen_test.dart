import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/genres/genres_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/movies/domain/movie_genre.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens with requested genre selected', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith(
            (_) async => HomeData(
              movies: [
                _movie(id: 'movie-1', title: 'Drama Movie', genre: 'Drama'),
                _movie(id: 'movie-2', title: 'Crime Movie', genre: 'Crime'),
              ],
              genres: const [
                MovieGenre(
                  id: 'genre-1',
                  name: 'Drama',
                  description: '',
                  pictureUrl: '',
                  iconUrl: '',
                  positionOnDashboard: 1,
                ),
                MovieGenre(
                  id: 'genre-2',
                  name: 'Crime',
                  description: '',
                  pictureUrl: '',
                  iconUrl: '',
                  positionOnDashboard: 2,
                ),
              ],
              orders: const [],
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: const GenresScreen(selectedGenre: 'Crime'),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Crime  •  1 Movies'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders languages from movie data', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith(
            (_) async => HomeData(
              movies: [
                _movie(
                  id: 'movie-1',
                  title: 'English Movie',
                  genre: 'Drama',
                  language: 'English',
                ),
                _movie(
                  id: 'movie-2',
                  title: 'Wolof Movie',
                  genre: 'Drama',
                  language: 'Wolof',
                ),
                _movie(
                  id: 'movie-3',
                  title: 'Another Wolof Movie',
                  genre: 'Comedy',
                  language: 'Wolof',
                ),
              ],
              genres: const [],
              orders: const [],
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: const GenresScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Languages'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Wolof'), findsOneWidget);
    expect(find.text('1 Movie'), findsOneWidget);
    expect(find.text('2 Movies'), findsOneWidget);
  });

  testWidgets('updates genre sort option', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith(
            (_) async => HomeData(
              movies: [
                _movie(
                  id: 'movie-1',
                  title: 'Short Drama',
                  genre: 'Drama',
                  duration: 45,
                ),
                _movie(
                  id: 'movie-2',
                  title: 'Long Drama',
                  genre: 'Drama',
                  duration: 120,
                ),
              ],
              genres: const [
                MovieGenre(
                  id: 'genre-1',
                  name: 'Drama',
                  description: '',
                  pictureUrl: '',
                  iconUrl: '',
                  positionOnDashboard: 1,
                ),
              ],
              orders: const [],
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: const GenresScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Title'), findsOneWidget);

    await tester.tap(find.text('Sort by'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duration'));
    await tester.pumpAndSettle();

    expect(find.text('Duration'), findsOneWidget);
  });
}

Movie _movie({
  required String id,
  required String title,
  required String genre,
  String language = 'Wolof',
  double duration = 75,
}) {
  return Movie(
    id: id,
    title: title,
    genre: genre,
    rating: '16',
    isBanner: false,
    isFree: false,
    viewersLimit: 0,
    price: 0,
    description: 'A test movie description.',
    actors: const ['Actor One'],
    countryName: 'Senegal',
    isoCode: 'SN',
    language: language,
    duration: duration,
    status: 'Published',
    releaseYear: '2026',
    releaseType: 'New Release',
    posterUrl: '',
    bannerUrl: '',
    trailerUrl: '',
    uploadedBy: 'tester',
    uploadDate: DateTime(2026, 6, 1),
  );
}
