import 'dart:async';

import 'package:africanmovies/core/network/network_status.dart';
import 'package:africanmovies/core/providers/network_providers.dart';
import 'package:africanmovies/shared/widgets/network_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('network gate warns without hiding app content', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final statusController = StreamController<NetworkStatus>();
    addTearDown(statusController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkStatusProvider.overrideWith((ref) {
            return statusController.stream;
          }),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) {
            return const MaterialApp(
              home: NetworkGate(child: Text('Online content')),
            );
          },
        ),
      ),
    );

    expect(find.text('Online content'), findsOneWidget);

    statusController.add(NetworkStatus.offline);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(find.text('Connection is unstable'), findsOneWidget);
    expect(find.text('Online content'), findsOneWidget);

    statusController.add(NetworkStatus.online);
    await tester.pump();
    await tester.pump();

    expect(find.text('Online content'), findsOneWidget);
    expect(find.text('Connection is unstable'), findsNothing);
  });
}
