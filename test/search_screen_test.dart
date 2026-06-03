import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('searches and renders movie results', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieSearchProvider.overrideWith((ref, query) async {
            if (query.toLowerCase() != 'love') return const [];

            return [
              _movie(
                id: 'movie-1',
                title: "Mother's Love",
                description:
                    'A mother fights to protect her family and happiness.',
              ),
            ];
          }),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SearchScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'love');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Results for "love"'), findsOneWidget);
    expect(find.text('1 result found'), findsOneWidget);
    expect(find.text("Mother's Love"), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    expect(find.text('12+'), findsOneWidget);
  });
}

Movie _movie({
  required String id,
  required String title,
  required String description,
}) {
  return Movie(
    id: id,
    title: title,
    genre: 'Drama',
    rating: '12',
    isBanner: false,
    isFree: false,
    viewersLimit: 0,
    price: 0.99,
    description: description,
    actors: const ['Actor One'],
    countryName: 'Nigeria',
    isoCode: 'NG',
    language: 'Yoruba',
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
