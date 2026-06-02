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
}

Movie _movie({
  required String id,
  required String title,
  required String genre,
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
    language: 'Wolof',
    duration: 75,
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
