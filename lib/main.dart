import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/platform/app_orientation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppOrientation.lockPortrait();
  MediaKit.ensureInitialized();

  runApp(const ProviderScope(child: AfricanMoviesApp()));
}
