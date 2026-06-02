import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/expiry_badge.dart';

class ContinueWatchingCard extends StatelessWidget {
  final String image;
  final String timeLeft;
  final double progress;
  final String? expiryText;
  final bool isExpiringSoon;

  const ContinueWatchingCard({
    super.key,
    required this.image,
    required this.timeLeft,
    required this.progress,
    this.expiryText,
    this.isExpiringSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92.w,
      height: 136.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: AppImage(source: image)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
          ),
          if (expiryText != null && expiryText!.isNotEmpty)
            Positioned(
              top: 6.h,
              left: 6.w,
              child: ExpiryBadge(text: expiryText!),
            ),
          Center(
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
                color: Colors.black.withValues(alpha: 0.22),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
          Positioned(
            left: 9.w,
            right: 9.w,
            bottom: 18.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5.h,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          Positioned(
            left: 9.w,
            bottom: 2.h,
            child: Text(
              timeLeft,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
