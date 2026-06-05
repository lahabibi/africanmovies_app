import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/auth/domain/auth_session.dart';
import 'package:africanmovies/features/movies/data/movie_repository.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/notifications/application/notification_providers.dart';
import 'package:africanmovies/features/notifications/domain/in_app_notification.dart';
import 'package:africanmovies/features/watchlist/application/watchlist_controller.dart';
import 'package:africanmovies/features/watchlist/watchlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders watchlist movies from provider', (tester) async {
    await _pumpWatchlist(
      tester,
      movies: [_movie(id: 'movie-1', title: 'Saved Movie')],
    );

    expect(find.text('My Watchlist'), findsOneWidget);
    expect(find.text('1 Title'), findsOneWidget);
    expect(find.text('Saved Movie'), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    expect(find.text('1h 15 min  •  2026'), findsOneWidget);
  });

  testWidgets('shows empty watchlist state', (tester) async {
    var browseTapped = false;

    await _pumpWatchlist(
      tester,
      movies: const [],
      onBrowseMovies: () => browseTapped = true,
    );

    expect(find.text('0 Titles'), findsOneWidget);
    expect(find.text('Your watchlist is empty'), findsOneWidget);

    await tester.tap(find.text('Browse Movies'));
    await tester.pump();

    expect(browseTapped, isTrue);
  });
}

Future<void> _pumpWatchlist(
  WidgetTester tester, {
  required List<Movie> movies,
  VoidCallback? onBrowseMovies,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(
            const AuthSession(
              token: 'test-token',
              user: AuthUser(
                id: 'user-1',
                email: 'user@test.com',
                username: 'User',
              ),
            ),
          ),
        ),
        notificationsControllerProvider.overrideWith(
          () => _TestNotificationsController(),
        ),
        watchlistControllerProvider.overrideWith(
          () => _TestWatchlistController(movies),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: WatchlistScreen(onBrowseMovies: onBrowseMovies),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Movie _movie({required String id, required String title}) {
  return Movie(
    id: id,
    title: title,
    genre: 'Drama',
    rating: '16',
    isBanner: false,
    isFree: false,
    viewersLimit: 0,
    price: 0.99,
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

class _TestAuthController extends AuthController {
  final AuthSession? session;

  _TestAuthController(this.session);

  @override
  Future<AuthSession?> build() async => session;
}

class _TestNotificationsController extends NotificationsController {
  @override
  Future<List<InAppNotification>> build() async => const [];
}

class _TestWatchlistController extends WatchlistController {
  final List<Movie> movies;

  _TestWatchlistController(this.movies);

  @override
  Future<List<Movie>> build() async => movies;

  @override
  Future<WatchlistAction> toggle(Movie movie) async {
    final currentMovies = state.asData?.value ?? movies;
    final isSaved = currentMovies.any((item) => item.id == movie.id);

    if (isSaved) {
      state = AsyncData(
        currentMovies.where((item) => item.id != movie.id).toList(),
      );
      return WatchlistAction.removed;
    }

    state = AsyncData([movie, ...currentMovies]);
    return WatchlistAction.added;
  }
}
