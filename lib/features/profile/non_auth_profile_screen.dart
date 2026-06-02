import 'package:africanmovies/features/auth/auth_screen.dart';
import 'package:africanmovies/features/profile/widgets/auth_feature_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/utils/responsive.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';

class NonAuthProfileScreen extends StatelessWidget {
  final ValueChanged<int>? onTabSelected;

  const NonAuthProfileScreen({super.key, this.onTabSelected});

  void _goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 4.h,
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: 12.h,
              ),
              child: Image.asset(AppAssets.logo, height: 32.h),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.formMaxWidth(context),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 22.h),
                        Container(
                          width: 118.w,
                          height: 118.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: .08),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .35),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                            size: 78.sp,
                          ),
                        ),

                        SizedBox(height: 28.h),

                        Text(
                          'Sign in to AfricanMovies',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        Text(
                          'Purchase movies, build your library,\nand continue watching across your devices.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .68),
                            fontSize: 13.sp,
                            height: 1.45,
                          ),
                        ),

                        SizedBox(height: 18.h),

                        Row(
                          children: [
                            AuthFeatureCard(
                              icon: Icons.video_library_outlined,
                              title: 'My Library',
                              subtitle: 'Access all your\npurchased movies',
                              onTap: () => _goToLogin(context),
                            ),
                            SizedBox(width: 14.w),
                            AuthFeatureCard(
                              icon: Icons.favorite_border_rounded,
                              title: 'Favorites',
                              subtitle: 'Save and access your\nfavorite movies',
                              onTap: () => _goToLogin(context),
                            ),
                          ],
                        ),

                        SizedBox(height: 14.h),

                        Row(
                          children: [
                            AuthFeatureCard(
                              icon: Icons.bookmark_border_rounded,
                              title: 'Watchlist',
                              subtitle: 'Save movies you want\nto watch later',
                              onTap: () => _goToLogin(context),
                            ),
                            SizedBox(width: 14.w),
                            AuthFeatureCard(
                              icon: Icons.devices_rounded,
                              title: 'Devices',
                              subtitle: 'Watch on your phone,\ntablet, or TV',
                              onTap: () => _goToLogin(context),
                            ),
                          ],
                        ),

                        SizedBox(height: 28.h),

                        SizedBox(
                          width: double.infinity,
                          height: 58.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _goToLogin(context),
                            icon: Icon(
                              Icons.email_outlined,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                            label: Text(
                              'Continue with Email',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 14.h),

                        SizedBox(
                          width: double.infinity,
                          height: 58.h,
                          child: OutlinedButton.icon(
                            onPressed: () => onTabSelected?.call(0),
                            icon: Icon(
                              Icons.explore_outlined,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                            label: Text(
                              'Browse Movies',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Only pay for the movies you watch.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .72),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 32.h),
                      ],
                    ),
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
