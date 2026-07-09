import 'package:africanmovies/features/favorite/favorite_screen.dart';
import 'package:africanmovies/features/favorite/application/favorite_controller.dart';
import 'package:africanmovies/features/profile/about_african_movies_screen.dart';
import 'package:africanmovies/features/profile/devices_screen.dart';
import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/profile/help_support_screen.dart';
import 'package:africanmovies/features/profile/purchase_history_screen.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/features/profile/widgets/profile_menu_tile.dart';
import 'package:africanmovies/features/profile/widgets/profile_stat_item.dart';
import 'package:africanmovies/features/profile/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/responsive.dart';
import '../auth/application/auth_device_providers.dart';
import '../auth/application/auth_controller.dart';
import '../auth/domain/auth_session.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final AuthUser user;
  final ValueChanged<int>? onTabSelected;
  final Future<void> Function()? onSignOut;

  const ProfileScreen({
    super.key,
    required this.user,
    this.onTabSelected,
    this.onSignOut,
  });

  static const _menuItems = [
    _ProfileMenuItem(
      icon: Icons.play_circle_outline_rounded,
      title: 'My Library',
      subtitle: 'Purchased movies • Active access',
    ),
    _ProfileMenuItem(
      icon: Icons.favorite_border_rounded,
      title: 'Favorite Movies',
      subtitle: 'Movies you’ve liked',
    ),
    _ProfileMenuItem(
      icon: Icons.bookmark_border_rounded,
      title: 'Watchlist',
      subtitle: 'Movies you want to watch',
    ),
    _ProfileMenuItem(
      icon: Icons.phone_iphone_rounded,
      title: 'Logged In Devices',
      subtitle: 'Manage active sessions',
      showsDeviceCount: true,
    ),
    _ProfileMenuItem(
      icon: Icons.receipt_long_outlined,
      title: 'Purchase History',
      subtitle: 'Orders, payments, and access status',
    ),
    _ProfileMenuItem(
      icon: Icons.headset_mic_outlined,
      title: 'Help & Support',
      subtitle: 'Get help or contact support',
    ),
    _ProfileMenuItem(
      icon: Icons.info_outline_rounded,
      title: 'About AfricanMovies',
      subtitle: 'App version 1.0.0',
    ),
    _ProfileMenuItem(
      icon: Icons.person_remove_outlined,
      title: 'Delete Account',
      subtitle: 'Permanently delete your account and personal data',
    ),
  ];

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            'Sign out?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'You’ll need to verify your email again to access your library and devices.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 14.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      await onSignOut?.call();
    }
  }

  Future<void> _confirmAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmationController = TextEditingController();
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var canDelete = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              title: Text(
                'Delete account?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This permanently removes your profile, devices, favorites, watchlist, and viewing activity. Transaction records required for refunds, accounting, and fraud prevention are anonymized and retained.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Type DELETE to continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  TextField(
                    controller: confirmationController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      setDialogState(() => canDelete = value == 'DELETE');
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'DELETE',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.cardBorder,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.danger),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: canDelete
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: canDelete
                          ? AppColors.danger
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    confirmationController.dispose();

    if (shouldDelete != true || !context.mounted) return;

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException
          ? error.message
          : 'We could not delete your account. Please try again.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = Responsive.headerHeight(context);
    final deviceCountText = ref
        .watch(authDevicesProvider)
        .when(
          data: (devices) => _formatDeviceCount(devices.length),
          loading: () => '...',
          error: (_, _) => null,
        );
    final favoriteCountText = ref
        .watch(favoriteControllerProvider)
        .when(
          data: (movies) => movies.length.toString(),
          loading: () => '...',
          error: (_, _) => '--',
        );
    final purchasedCountText = ref
        .watch(homeDataProvider)
        .when(
          data: (data) => data.purchasedMovieCount.toString(),
          loading: () => '...',
          error: (_, _) => '--',
        );

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),

                      Row(
                        children: [
                          ProfileAvatar(
                            profileUrl: user.profileUrl,
                            size: 96.w,
                          ),

                          SizedBox(width: 18.w),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username.isEmpty
                                      ? 'User'
                                      : user.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 10.w),

                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.heroButton,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.heroButton,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ProfileStatItem(
                                icon: Icons.confirmation_number_outlined,
                                value: purchasedCountText,
                                label: 'Purchased Movies',
                              ),
                            ),
                            Container(
                              width: 1.w,
                              height: 58.h,
                              color: AppColors.cardBorder,
                            ),
                            Expanded(
                              child: ProfileStatItem(
                                icon: Icons.favorite_rounded,
                                value: favoriteCountText,
                                label: 'Favorited Movies',
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10.h),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: List.generate(_menuItems.length, (index) {
                            final item = _menuItems[index];

                            return ProfileMenuTile(
                              icon: item.icon,
                              title: item.title,
                              subtitle: item.subtitle,
                              trailingText: item.showsDeviceCount
                                  ? deviceCountText
                                  : null,
                              showDivider: index != _menuItems.length - 1,
                              onTap: () {
                                switch (item.title) {
                                  case 'My Library':
                                    onTabSelected?.call(3);
                                    break;

                                  case 'Watchlist':
                                    onTabSelected?.call(2);
                                    break;

                                  case 'Favorite Movies':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const FavoriteScreen(),
                                      ),
                                    );
                                    break;

                                  case 'Logged In Devices':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const LoggedInDevicesScreen(),
                                      ),
                                    );
                                    break;

                                  case 'Purchase History':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PurchaseHistoryScreen(),
                                      ),
                                    );
                                    break;

                                  case 'About AfricanMovies':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AboutAfricanMoviesScreen(),
                                      ),
                                    );
                                    break;

                                  case 'Help & Support':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const HelpSupportScreen(),
                                      ),
                                    );
                                    break;

                                  case 'Delete Account':
                                    _confirmAccountDeletion(context, ref);
                                    break;
                                }
                              },
                            );
                          }),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      InkWell(
                        onTap: onSignOut == null
                            ? null
                            : () => _confirmSignOut(context),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: AppColors.card.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: AppColors.danger,
                                size: 22.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: headerHeight, child: const HomeHeader()),
          ),
        ],
      ),
    );
  }

  String _formatDeviceCount(int count) {
    return '$count ${count == 1 ? 'device' : 'devices'}';
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showsDeviceCount;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showsDeviceCount = false,
  });
}
