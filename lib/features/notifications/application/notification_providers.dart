import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../movies/domain/movie.dart';
import '../data/notification_repository.dart';
import '../domain/in_app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(cacheStore: ref.watch(jsonCacheStoreProvider));
});

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<InAppNotification>>(
      NotificationsController.new,
    );

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsControllerProvider)
      .maybeWhen(
        data: (notifications) =>
            notifications.where((notification) => notification.isUnread).length,
        orElse: () => 0,
      );
});

class NotificationsController extends AsyncNotifier<List<InAppNotification>> {
  @override
  Future<List<InAppNotification>> build() {
    return ref.watch(notificationRepositoryProvider).readNotifications();
  }

  Future<void> syncNewReleases(List<Movie> movies) async {
    final notifications = await ref
        .read(notificationRepositoryProvider)
        .syncNewReleases(movies);

    state = AsyncData(notifications);
  }

  Future<void> addPurchaseSuccess(Movie movie) async {
    final notifications = await ref
        .read(notificationRepositoryProvider)
        .addPurchaseSuccess(movie);

    state = AsyncData(notifications);
  }

  Future<void> addRentalExpiry({
    required Movie movie,
    required DateTime expiresAt,
  }) async {
    final notifications = await ref
        .read(notificationRepositoryProvider)
        .addRentalExpiry(movie: movie, expiresAt: expiresAt);

    state = AsyncData(notifications);
  }

  Future<void> markAsRead(String notificationId) async {
    final notifications = await ref
        .read(notificationRepositoryProvider)
        .markAsRead(notificationId);

    state = AsyncData(notifications);
  }

  Future<void> markAllAsRead() async {
    final notifications = await ref
        .read(notificationRepositoryProvider)
        .markAllAsRead();

    state = AsyncData(notifications);
  }
}
