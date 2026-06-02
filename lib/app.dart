import 'package:africanmovies/features/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AfricanMoviesApp extends StatelessWidget {
  const AfricanMoviesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      enableScaleWH: () => Responsive.shouldScaleScreenUtil,
      enableScaleText: () => Responsive.shouldScaleScreenUtil,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AfricanMovies',
          theme: AppTheme.darkTheme,
          home: child,
        );
      },
      child: const MainScreen(),
    );
  }
}
