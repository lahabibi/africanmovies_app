import 'package:africanmovies/core/storage/json_cache_store.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/notifications/data/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('baselines existing new releases before notifying', () async {
    final repository = NotificationRepository(cacheStore: JsonCacheStore());

    final firstSync = await repository.syncNewReleases([
      _movie(id: 'movie-1', title: 'First Movie'),
    ]);

    expect(firstSync, isEmpty);

    final secondSync = await repository.syncNewReleases([
      _movie(id: 'movie-2', title: 'Second Movie'),
      _movie(id: 'movie-1', title: 'First Movie'),
    ]);

    expect(secondSync, hasLength(1));
    expect(secondSync.first.id, 'new-release-movie-2');
    expect(secondSync.first.isUnread, isTrue);

    final thirdSync = await repository.syncNewReleases([
      _movie(id: 'movie-2', title: 'Second Movie'),
      _movie(id: 'movie-1', title: 'First Movie'),
    ]);

    expect(thirdSync, hasLength(1));
  });

  test('marks all notifications as read', () async {
    final repository = NotificationRepository(cacheStore: JsonCacheStore());

    await repository.syncNewReleases([
      _movie(id: 'movie-1', title: 'First Movie'),
    ]);
    await repository.syncNewReleases([
      _movie(id: 'movie-2', title: 'Second Movie'),
      _movie(id: 'movie-1', title: 'First Movie'),
    ]);

    final notifications = await repository.markAllAsRead();

    expect(notifications, hasLength(1));
    expect(notifications.first.isRead, isTrue);
  });
}

Movie _movie({required String id, required String title}) {
  return Movie(
    id: id,
    title: title,
    genre: 'Drama',
    rating: '12',
    isBanner: false,
    isFree: false,
    viewersLimit: 0,
    price: 0.99,
    description: 'A test movie description.',
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
