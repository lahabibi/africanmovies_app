import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/shared/widgets/section_movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, {required bool showFreeBadge}) {
    return tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SectionMovieCard(image: '', showFreeBadge: showFreeBadge),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows free badge only when enabled', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await pumpCard(tester, showFreeBadge: false);
    expect(find.text('FREE'), findsNothing);

    await pumpCard(tester, showFreeBadge: true);
    expect(find.text('FREE'), findsOneWidget);
  });
}
