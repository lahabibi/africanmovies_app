import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_session.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profileUrl;
  final double size;
  final double borderWidth;
  final bool showBorder;
  final bool isBusy;

  const ProfileAvatar({
    super.key,
    required this.profileUrl,
    required this.size,
    this.borderWidth = 1.5,
    this.showBorder = true,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasProfileImage = AuthUser.hasProfileImageUrl(profileUrl);
    final iconPadding = size * 0.28;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(showBorder ? 2.w : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.heroButton, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasProfileImage)
              Image.network(
                profileUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _ProfileIconFallback(padding: iconPadding),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return _ProfileIconFallback(padding: iconPadding);
                },
              )
            else
              _ProfileIconFallback(padding: iconPadding),
            if (isBusy)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileIconFallback extends StatelessWidget {
  final double padding;

  const _ProfileIconFallback({required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      alignment: Alignment.center,
      padding: EdgeInsets.all(padding),
      child: Image.asset(
        AppAssets.user,
        color: AppColors.primary,
        fit: BoxFit.contain,
      ),
    );
  }
}
