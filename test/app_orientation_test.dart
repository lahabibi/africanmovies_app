import 'package:africanmovies/core/platform/app_orientation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('locks ordinary app screens to portrait', () async {
    await AppOrientation.lockPortrait();

    expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
    expect(calls.single.arguments, ['DeviceOrientation.portraitUp']);
  });

  test('allows media screens to enter either landscape direction', () async {
    await AppOrientation.lockLandscape();

    expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
    expect(calls.single.arguments, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
  });
}
