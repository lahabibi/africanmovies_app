import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

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
    final isTablet = Responsive.isTablet(context);
    final glowSize = isTablet ? 300.0 : 260.w;
    final bottomGlowSize = isTablet ? 280.0 : 240.w;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          /// Top blue glow
          Positioned(
            top: isTablet ? -130 : -120.h,
            right: isTablet ? -90 : -80.w,
            child: Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),

          /// Bottom subtle glow
          Positioned(
            bottom: isTablet ? -150 : -140.h,
            left: isTablet ? -110 : -100.w,
            child: Container(
              width: bottomGlowSize,
              height: bottomGlowSize,
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
                      horizontal: Responsive.horizontalPadding(context),
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
