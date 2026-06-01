import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_screen_header.dart';

class NoSavedCardScreen extends StatelessWidget {
  const NoSavedCardScreen({super.key});

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
                  SizedBox(height: 22.h),

                  Image.asset(
                    AppAssets.noCard,
                    width: 300.w,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 18.h),

                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.heroButton.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.heroButton,
                      size: 22.sp,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  Text(
                    'No saved payment methods',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 14.h),

                  Text(
                    'You don’t have any cards saved yet. Add a payment\nmethod during checkout for a seamless and\nsecure experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.55,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  SizedBox(height: 38.h),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(22.w),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.heroButton,
                          size: 54.sp,
                        ),
                        SizedBox(width: 18.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure and Protected',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Your payment information is encrypted and secure. We never store your CVV.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  height: 1.45,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 34.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.headset_mic_outlined,
                        color: AppColors.heroButton,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Need help?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'Contact our support team.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.heroButton,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.heroButton,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppScreenHeader(),
          ),
        ],
      ),
    );
  }
}