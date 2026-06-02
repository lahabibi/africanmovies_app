import 'package:africanmovies/features/profile/widgets/profile_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_screen_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),

                      Text(
                        'Help & Support',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        'We’re here to help you. Find answers\nor get in touch with our team.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 18.h),

                      Text(
                        'Popular Topics',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                          children: const [
                            ProfileMenuTile(
                              icon: Icons.play_circle_outline_rounded,
                              title: 'Getting Started',
                              subtitle:
                                  'Learn how to sign up and start watching',
                            ),
                            ProfileMenuTile(
                              icon: Icons.credit_card_rounded,
                              title: 'Payment & Billing',
                              subtitle:
                                  'Payment methods, failed payments and more',
                            ),
                            ProfileMenuTile(
                              icon: Icons.person_outline_rounded,
                              title: 'Account & Profile',
                              subtitle:
                                  'Update your profile and account information',
                            ),
                            ProfileMenuTile(
                              icon: Icons.smart_display_outlined,
                              title: 'Watching & Playback',
                              subtitle:
                                  'Stream, video quality and playback issues',
                            ),
                            ProfileMenuTile(
                              icon: Icons.verified_user_outlined,
                              title: 'Security & Privacy',
                              subtitle: 'Keep your account and data secure',
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      Divider(color: AppColors.cardBorder),

                      SizedBox(height: 18.h),

                      Text(
                        'Still Need Help?',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        'Can’t find what you’re looking for?\nOur support team is ready to help.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                                vertical: 16.h,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.headset_mic_outlined,
                                    color: AppColors.heroButton,
                                    size: 30.sp,
                                  ),
                                  SizedBox(width: 18.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contact Support',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          'Our team typically replies within\n24 hours',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            height: 1.45,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: AppButton(
                                      text: 'Contact Us',
                                      width: 112.w,
                                      height: 42.h,
                                      fontSize: 13.sp,
                                      borderRadius: AppRadius.sm,
                                      backgroundColor: const Color(0xFF5CCBFF),
                                      borderColor: const Color(0xFF5CCBFF),
                                      textColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: AppColors.cardBorder),
                            const ProfileMenuTile(
                              icon: Icons.email_outlined,
                              title: 'Email Us',
                              subtitle: 'info@africanmovies.com',
                            ),
                            const ProfileMenuTile(
                              icon: Icons.help_outline_rounded,
                              title: 'FAQ',
                              subtitle: 'Browse frequently asked questions',
                              showDivider: false,
                            ),
                          ],
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
            child: SizedBox(
              height: headerHeight,
              child: const AppScreenHeader(),
            ),
          ),
        ],
      ),
    );
  }
}
