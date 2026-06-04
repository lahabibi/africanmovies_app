import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/home/widgets/hero_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHeroBanner(
    WidgetTester tester, {
    required String title,
    VoidCallback? onWatchNowTap,
    VoidCallback? onTrailerTap,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              height: 210,
              child: HeroBanner(
                type: HeroBannerType.image,
                image: '',
                title: title,
                description: 'A movie description.',
                year: '2026',
                genre: 'Drama',
                releaseType: 'New Release',
                duration: '1h 15 min',
                ageRating: '16+',
                onWatchNowTap: onWatchNowTap,
                onTrailerTap: onTrailerTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('hero action buttons trigger their callbacks', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var watchTapCount = 0;
    var trailerTapCount = 0;

    await pumpHeroBanner(
      tester,
      title: 'Lion Heart',
      onWatchNowTap: () => watchTapCount++,
      onTrailerTap: () => trailerTapCount++,
    );

    await tester.tap(find.text('Watch Now'));
    await tester.pump();
    expect(watchTapCount, 1);

    await tester.tap(find.text('Trailer'));
    await tester.pump();
    expect(trailerTapCount, 1);
  });

  testWidgets('hero title balances four to six word titles', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpHeroBanner(tester, title: 'One Two Three Four');
    expect(find.text('ONE TWO\nTHREE FOUR'), findsOneWidget);

    await pumpHeroBanner(tester, title: 'One Two Three Four Five');
    expect(find.text('ONE TWO THREE\nFOUR FIVE'), findsOneWidget);

    await pumpHeroBanner(tester, title: 'One Two Three Four Five Six');
    expect(find.text('ONE TWO THREE\nFOUR FIVE SIX'), findsOneWidget);
  });
}
