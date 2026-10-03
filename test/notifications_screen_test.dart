import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/notifications/application/notification_providers.dart';
import 'package:africanmovies/features/notifications/domain/in_app_notification.dart';
import 'package:africanmovies/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clears all notifications after confirmation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsControllerProvider.overrideWith(
            () => _TestNotificationsController([
              InAppNotification(
                id: 'notification-1',
                type: InAppNotificationType.newRelease,
                title: 'New release: Test Movie',
                message: 'Now available to watch on AfricanMovies.',
                createdAt: DateTime(2026, 10, 3),
              ),
            ]),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: const NotificationsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('New release: Test Movie'), findsOneWidget);
    expect(find.byKey(const Key('notifications_clear_all')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notifications_clear_all')));
    await tester.pumpAndSettle();

    expect(find.text('Clear all notifications?'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(find.text('New release: Test Movie'), findsNothing);
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.byKey(const Key('notifications_clear_all')), findsNothing);
  });
}

class _TestNotificationsController extends NotificationsController {
  final List<InAppNotification> notifications;

  _TestNotificationsController(this.notifications);

  @override
  Future<List<InAppNotification>> build() async => notifications;

  @override
  Future<void> clearAll() async {
    state = const AsyncData<List<InAppNotification>>([]);
  }
}
