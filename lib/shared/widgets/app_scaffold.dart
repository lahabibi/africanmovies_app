import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool usePadding;

  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.usePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          /// Top blue glow
          Positioned(
            top: -120.h,
            right: -80.w,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),

          /// Bottom subtle glow
          Positioned(
            bottom: -140.h,
            left: -100.w,
            child: Container(
              width: 240.w,
              height: 240.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: usePadding
                  ? EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              )
                  : EdgeInsets.zero,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}