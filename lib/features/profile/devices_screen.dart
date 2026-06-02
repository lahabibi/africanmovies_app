import 'package:africanmovies/features/profile/widgets/device_card.dart';
import 'package:africanmovies/features/profile/widgets/section_title.dart';
import 'package:africanmovies/features/profile/widgets/security_info_card.dart';
import 'package:africanmovies/shared/widgets/app_screen_header_with_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

class LoggedInDevicesScreen extends StatelessWidget {
  const LoggedInDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);

    final devices = [
      DeviceInfo(
        name: 'MacBook Air',
        location: 'Abuja, Nigeria',
        os: 'macOS 14.4',
        lastActive: 'Yesterday, 11:32 PM',
        icon: Icons.laptop_mac_rounded,
      ),
      DeviceInfo(
        name: 'Android Phone',
        location: 'Port Harcourt, Nigeria',
        os: 'Android 14',
        lastActive: '2 days ago',
        icon: Icons.phone_android_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8.h,
                horizontalPadding,
                12.h,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.formMaxWidth(context),
                  ),
                  child: const AppScreenHeaderWithTitle(
                    title: 'Logged in devices',
                  ),
                ),
              ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 92.w,
                            height: 92.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: .08),
                            ),
                            child: Center(
                              child: Container(
                                width: 62.w,
                                height: 62.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(
                                    alpha: .10,
                                  ),
                                ),
                                child: Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.primary,
                                  size: 38.sp,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8.h),

                        Center(
                          child: Text(
                            'Manage your devices',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        Center(
                          child: Text(
                            'You are signed in to AfricanMovies on the\ndevices below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .62),
                              fontSize: 13.sp,
                              height: 1.45,
                            ),
                          ),
                        ),

                        SizedBox(height: 14.h),

                        SectionTitle('THIS DEVICE'),
                        SizedBox(height: 10.h),

                        DeviceCard(
                          device: DeviceInfo(
                            name: 'iPhone 14 Pro',
                            location: 'Lagos, Nigeria',
                            os: 'iOS 17.4',
                            icon: Icons.phone_iphone_rounded,
                            isCurrentDevice: true,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        SectionTitle('OTHER DEVICES'),
                        SizedBox(height: 12.h),

                        ...devices.map(
                          (device) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: DeviceCard(
                              device: device,
                              onSignOut: () {
                                // TODO: call sign out device API
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        const SecurityInfoCard(),

                        SizedBox(height: 26.h),

                        SizedBox(
                          width: double.infinity,
                          height: 58.h,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: call sign out all devices API
                            },
                            icon: Icon(
                              Icons.logout_rounded,
                              size: 26.sp,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Sign out of all devices',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.heroButton,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
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

class DeviceInfo {
  final String name;
  final String location;
  final String os;
  final String? lastActive;
  final IconData icon;
  final bool isCurrentDevice;

  DeviceInfo({
    required this.name,
    required this.location,
    required this.os,
    required this.icon,
    this.lastActive,
    this.isCurrentDevice = false,
  });
}
