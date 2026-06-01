import 'package:africanmovies/features/favorite/favorite_screen.dart';
import 'package:africanmovies/features/profile/about_african_movies_screen.dart';
import 'package:africanmovies/features/profile/devices_screen.dart';
import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/profile/help_support_screen.dart';
import 'package:africanmovies/features/profile/no_saved_card_screen.dart';
import 'package:africanmovies/features/profile/payment_details_screen.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/features/profile/widgets/profile_menu_tile.dart';
import 'package:africanmovies/features/profile/widgets/profile_stat_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final ValueChanged<int>? onTabSelected;
  const ProfileScreen({super.key, this.onTabSelected});

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
      trailingText: '2 devices',
    ),
    _ProfileMenuItem(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Payment Details',
      subtitle: 'Manage your saved payment methods',
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
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 48.h),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Column(
                children: [
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 96.w,
                            height: 96.w,
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.heroButton,
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                AppAssets.profile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Positioned(
                          //   right: 0,
                          //   bottom: 4.h,
                          //   child: Container(
                          //     width: 28.w,
                          //     height: 28.w,
                          //     decoration: const BoxDecoration(
                          //       shape: BoxShape.circle,
                          //       color: AppColors.heroButton,
                          //     ),
                          //     child: Icon(
                          //       Icons.edit_rounded,
                          //       color: Colors.white,
                          //       size: 14.sp,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),

                      SizedBox(width: 18.w),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summaya Ibrahim',
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
                              'summaya.ibrahim@gmail.com',
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
                            borderRadius: BorderRadius.circular(AppRadius.sm),
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
                            value: '12',
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
                            value: '18',
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
                          trailingText: item.trailingText,
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
                                    builder: (_) =>
                                    const FavoriteScreen(),
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

                              case 'Payment Details':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PaymentDetailsScreen(),
                                  ),
                                );
                                break;

                              case 'About AfricanMovies':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AboutAfricanMoviesScreen(),
                                  ),
                                );
                                break;

                              case 'Help & Support':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HelpSupportScreen(),
                                  ),
                                );
                                break;
                            }
                          },
                        );
                      }),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Container(
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
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: 48.h, child: const HomeHeader()),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
  });
}
