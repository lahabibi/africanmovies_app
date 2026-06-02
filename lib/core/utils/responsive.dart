import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
  Responsive._();

  static const double tabletShortestSide = 600;

  static bool get shouldScaleScreenUtil {
    final screen = ScreenUtil();
    return math.min(screen.screenWidth, screen.screenHeight) <
        tabletShortestSide;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= tabletShortestSide;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 900;
  }

  static double horizontalPadding(BuildContext context) {
    if (!isTablet(context)) return 10.w;
    return isWide(context) ? 32 : 24;
  }

  static double headerHeight(BuildContext context) {
    return isTablet(context) ? 56 : 48.h;
  }

  static double contentMaxWidth(BuildContext context) {
    if (!isTablet(context)) return double.infinity;
    return isWide(context) ? 900 : 720;
  }

  static double formMaxWidth(BuildContext context) {
    if (!isTablet(context)) return double.infinity;
    return 560;
  }

  static double heroHeight(BuildContext context) {
    if (!isTablet(context)) return 210.h;

    final size = MediaQuery.sizeOf(context);
    final contentWidth = size.width - (horizontalPadding(context) * 2);
    final ratio = isWide(context) ? 0.34 : 0.40;

    return (contentWidth * ratio).clamp(260, 340).toDouble();
  }

  static double detailHeroHeight(BuildContext context) {
    if (!isTablet(context)) return 340.h;

    final width = MediaQuery.sizeOf(context).width;
    return (width * 0.42).clamp(340, 460).toDouble();
  }

  static int posterGridColumns(BuildContext context) {
    final contentWidth =
        MediaQuery.sizeOf(context).width - (horizontalPadding(context) * 2);

    if (contentWidth >= 1080) return 6;
    if (contentWidth >= 840) return 5;
    if (contentWidth >= 600) return 4;
    return 3;
  }

  static double gridSpacing(BuildContext context) {
    return isTablet(context) ? 12 : 8.w;
  }

  static double posterGridAspectRatio(BuildContext context) {
    return isTablet(context) ? 0.52 : 0.43;
  }

  static double compactPosterGridAspectRatio(BuildContext context) {
    return isTablet(context) ? 0.66 : 0.62;
  }

  static double bottomNavMaxWidth(BuildContext context) {
    return isWide(context) ? 640 : 560;
  }
}
