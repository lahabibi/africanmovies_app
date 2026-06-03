import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/auth_screen.dart';
import '../../notifications/application/notification_providers.dart';
import '../../notifications/notifications_screen.dart';
import '../../search/search_screen.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSession = ref
        .watch(authControllerProvider)
        .maybeWhen(data: (session) => session != null, orElse: () => false);
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    return Row(
      children: [
        Image.asset(AppAssets.logo, height: 32.h),
        const Spacer(),
        _HeaderIcon(
          key: Key('home_header_search'),
          icon: AppAssets.search,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
        SizedBox(width: 12.w),
        _HeaderIcon(
          key: Key('home_header_notification'),
          icon: AppAssets.notification,
          badgeCount: unreadNotificationCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        SizedBox(width: 12.w),
        if (hasSession) ...[
          Container(
            key: const Key('home_header_profile'),
            width: 36.w,
            height: 36.w,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.asset(AppAssets.profile, fit: BoxFit.cover),
          ),
        ] else
          _HeaderIcon(
            key: const Key('home_header_profile_icon'),
            icon: AppAssets.user,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback? onTap;
  final int badgeCount;

  const _HeaderIcon({
    super.key,
    required this.icon,
    this.color = AppColors.textPrimary,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Image.asset(icon, width: 19.w, height: 19.w, color: color),
            ),
            if (badgeCount > 0)
              Positioned(
                key: const Key('home_header_notification_badge'),
                top: -3.h,
                right: -3.w,
                child: _NotificationBadge(count: badgeCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final int count;

  const _NotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : count.toString();

    return Container(
      constraints: BoxConstraints(minWidth: 16.w),
      height: 16.w,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.background, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.background,
          fontSize: 9.sp,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
