import 'package:africanmovies/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the AfricanMovies home shell', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AfricanMoviesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Home'), findsAtLeastNWidgets(1));
    expect(find.text('Genres'), findsAtLeastNWidgets(1));
    expect(find.text('Watchlist'), findsAtLeastNWidgets(1));
    expect(find.text('Continue Watching'), findsAtLeastNWidgets(1));
  });
}
