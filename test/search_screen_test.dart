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

  testWidgets('keeps compact phone result content inside the card', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const description =
        'A determined family faces a difficult journey while protecting the '
        'people and home they love most.';
    final movie = _movie(
      id: 'compact-movie',
      title: 'The Extraordinary Lion Heart Story',
      description: description,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieSearchProvider.overrideWith((ref, query) async {
            return query.toLowerCase() == 'lion' ? [movie] : const [];
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
    await tester.enterText(find.byType(TextField), 'lion');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    final cardFinder = find.byKey(
      const ValueKey('search-result-card-compact-movie'),
    );
    final ageFinder = find.byKey(
      const ValueKey('search-result-age-compact-movie'),
    );
    final cardRect = tester.getRect(cardFinder);
    final descriptionRect = tester.getRect(find.text(description));
    final ageRect = tester.getRect(ageFinder);

    expect(cardFinder, findsOneWidget);
    expect(descriptionRect.height, greaterThanOrEqualTo(24));
    expect(descriptionRect.left, greaterThanOrEqualTo(cardRect.left));
    expect(descriptionRect.right, lessThanOrEqualTo(cardRect.right));
    expect(ageRect.bottom, lessThanOrEqualTo(cardRect.bottom));
    expect(tester.takeException(), isNull);
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
