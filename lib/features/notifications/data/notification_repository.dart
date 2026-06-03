import '../../../core/storage/json_cache_store.dart';
import '../../movies/domain/movie.dart';
import '../domain/in_app_notification.dart';

class NotificationRepository {
  NotificationRepository({required JsonCacheStore cacheStore})
    : _cacheStore = cacheStore;

  static const _itemsKey = 'notifications.items.v1';
  static const _seenNewReleaseIdsKey = 'notifications.seen_new_release_ids.v1';
  static const _newReleaseBaselineKey = 'notifications.new_release_baseline.v1';
  static const _maxStoredNotifications = 100;
  static const _maxNewReleaseNotificationsPerSync = 5;

  final JsonCacheStore _cacheStore;

  Future<List<InAppNotification>> readNotifications() async {
    final cached = await _cacheStore.read(_itemsKey);
    final data = cached?.data;
    if (data is! List) return const [];

    return _sortNotifications(
      data
          .whereType<Map>()
          .map(
            (item) =>
                InAppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((notification) => notification.id.isNotEmpty)
          .toList(),
    );
  }

  Future<List<InAppNotification>> syncNewReleases(List<Movie> movies) async {
    final currentNotifications = await readNotifications();
    final movieIds = _movieIds(movies);
    final hasBaseline = await _hasNewReleaseBaseline();

    if (!hasBaseline) {
      await _writeSeenNewReleaseIds(movieIds);
      await _writeNewReleaseBaseline();
      return currentNotifications;
    }

    final seenIds = await _readSeenNewReleaseIds();
    final existingNotificationIds = currentNotifications
        .map((notification) => notification.id)
        .toSet();
    final newMovies = movies
        .where((movie) => movie.id.isNotEmpty)
        .where((movie) => !seenIds.contains(movie.id))
        .where(
          (movie) =>
              !existingNotificationIds.contains('new-release-${movie.id}'),
        )
        .toList();

    await _writeSeenNewReleaseIds({...seenIds, ...movieIds});
    if (newMovies.isEmpty) return currentNotifications;

    newMovies.sort((left, right) {
      final leftDate =
          left.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);

      return rightDate.compareTo(leftDate);
    });

    final notifications = newMovies
        .take(_maxNewReleaseNotificationsPerSync)
        .map(InAppNotification.newRelease)
        .toList();

    return _writeNotifications([...notifications, ...currentNotifications]);
  }

  Future<List<InAppNotification>> addPurchaseSuccess(Movie movie) {
    return _addNotification(InAppNotification.purchaseSuccess(movie));
  }

  Future<List<InAppNotification>> addRentalExpiry({
    required Movie movie,
    required DateTime expiresAt,
  }) {
    return _addNotification(
      InAppNotification.rentalExpiry(movie: movie, expiresAt: expiresAt),
    );
  }

  Future<List<InAppNotification>> markAsRead(String notificationId) async {
    final now = DateTime.now();
    final notifications = (await readNotifications()).map((notification) {
      if (notification.id != notificationId) return notification;

      return notification.markRead(now);
    }).toList();

    return _writeNotifications(notifications);
  }

  Future<List<InAppNotification>> markAllAsRead() async {
    final now = DateTime.now();
    final notifications = (await readNotifications())
        .map((notification) => notification.markRead(now))
        .toList();

    return _writeNotifications(notifications);
  }

  Future<List<InAppNotification>> _addNotification(
    InAppNotification notification,
  ) async {
    final notifications = await readNotifications();
    final existingIds = notifications.map((item) => item.id).toSet();
    if (existingIds.contains(notification.id)) return notifications;

    return _writeNotifications([notification, ...notifications]);
  }

  Future<List<InAppNotification>> _writeNotifications(
    List<InAppNotification> notifications,
  ) async {
    final sorted = _sortNotifications(
      notifications,
    ).take(_maxStoredNotifications).toList();

    await _cacheStore.write(
      _itemsKey,
      sorted.map((notification) => notification.toJson()).toList(),
    );

    return sorted;
  }

  Future<Set<String>> _readSeenNewReleaseIds() async {
    final cached = await _cacheStore.read(_seenNewReleaseIdsKey);
    final data = cached?.data;
    if (data is! List) return const <String>{};

    return data
        .map((item) => item.toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _writeSeenNewReleaseIds(Set<String> ids) {
    return _cacheStore.write(_seenNewReleaseIdsKey, ids.toList()..sort());
  }

  Future<bool> _hasNewReleaseBaseline() async {
    final cached = await _cacheStore.read(_newReleaseBaselineKey);

    return cached?.data == true;
  }

  Future<void> _writeNewReleaseBaseline() {
    return _cacheStore.write(_newReleaseBaselineKey, true);
  }

  Set<String> _movieIds(List<Movie> movies) {
    return movies.map((movie) => movie.id).where((id) => id.isNotEmpty).toSet();
  }

  List<InAppNotification> _sortNotifications(
    List<InAppNotification> notifications,
  ) {
    final sorted = [...notifications];
    sorted.sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return sorted;
  }
}
