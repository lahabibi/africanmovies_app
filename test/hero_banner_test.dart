import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/home/widgets/hero_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hero buttons do not trigger the banner tap', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var bannerTapCount = 0;
    var watchTapCount = 0;
    var trailerTapCount = 0;

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
                title: 'Lion Heart',
                description: 'A movie description.',
                year: '2026',
                genre: 'Drama',
                releaseType: 'New Release',
                duration: '1h 15 min',
                ageRating: '16+',
                onTap: () => bannerTapCount++,
                onWatchNowTap: () => watchTapCount++,
                onTrailerTap: () => trailerTapCount++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Watch Now'));
    await tester.pump();
    expect(watchTapCount, 1);
    expect(bannerTapCount, 0);

    await tester.tap(find.text('Trailer'));
    await tester.pump();
    expect(trailerTapCount, 1);
    expect(bannerTapCount, 0);

    await tester.tap(find.text('FEATURED MOVIE'));
    await tester.pump();
    expect(bannerTapCount, 1);
  });
}
