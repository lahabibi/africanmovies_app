import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/auth/auth_screen.dart';
import 'package:africanmovies/features/auth/domain/auth_session.dart';
import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows profile icon when unauthenticated', (tester) async {
    await _pumpHeader(tester, session: null);

    expect(find.byKey(const Key('home_header_search')), findsOneWidget);
    expect(find.byKey(const Key('home_header_notification')), findsOneWidget);
    expect(find.byKey(const Key('home_header_profile')), findsNothing);
    expect(find.byKey(const Key('home_header_profile_icon')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_header_profile_icon')));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('shows notification and profile when authenticated', (
    tester,
  ) async {
    await _pumpHeader(
      tester,
      session: const AuthSession(
        token: 'test-token',
        user: AuthUser(id: 'user-1', email: 'user@test.com', username: 'User'),
      ),
    );

    expect(find.byKey(const Key('home_header_search')), findsOneWidget);
    expect(find.byKey(const Key('home_header_notification')), findsOneWidget);
    expect(find.byKey(const Key('home_header_profile')), findsOneWidget);
    expect(find.byKey(const Key('home_header_profile_icon')), findsNothing);
  });
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required AuthSession? session,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _TestAuthController(session)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: HomeHeader()),
        ),
      ),
    ),
  );

  await tester.pump();
}

class _TestAuthController extends AuthController {
  final AuthSession? session;

  _TestAuthController(this.session);

  @override
  Future<AuthSession?> build() async => session;
}
