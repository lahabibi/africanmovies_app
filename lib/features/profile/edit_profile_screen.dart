import 'package:africanmovies/shared/widgets/app_button.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_scaffold.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      usePadding: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.formMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),

                AppScreenHeader(),

                SizedBox(height: 26.h),

                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                Text(
                  'Update your profile information.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 26.h),

                Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 18.h),

                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 146.w,
                            height: 146.w,
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.heroButton,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                AppAssets.profile,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 10.h,
                            child: Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF5CCBFF),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.heroButton.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 14.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      Text(
                        'Tap the camera icon to change\nyour profile picture.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                Divider(color: AppColors.cardBorder),

                SizedBox(height: 8.h),

                Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 14.h),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heroButton,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Summaya Ibrahim',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                Text(
                  'This is the name other users will see on your profile.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 24.h),

                AppButton(
                  text: 'Save Changes',
                  height: 50.h,
                  borderRadius: AppRadius.sm,
                  backgroundColor: const Color(0xFF5CCBFF),
                  borderColor: const Color(0xFF5CCBFF),
                  fontSize: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
