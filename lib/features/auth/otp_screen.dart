import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_scaffold.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);

    return AppScaffold(
      usePadding: false,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.formMaxWidth(context),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10.h),

                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 56.h),

                    Image.asset(AppAssets.logo, height: 44.h),

                    SizedBox(height: 28.h),

                    Text(
                      'Verify your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    Text(
                      'We’ve sent a 6-digit One-Time Passcode (OTP)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: 6.h),

                    Text(
                      'to john.doe@email.com',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: 40.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => _OtpBox(isActive: index == 0),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    RichText(
                      text: TextSpan(
                        text: 'Code expires in ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: '04:59',
                            style: TextStyle(
                              color: AppColors.heroButton,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    AppButton(
                      text: 'Verify OTP',
                      height: 50.h,
                      borderRadius: AppRadius.sm,
                      backgroundColor: const Color(0xFF12B8F7),
                      borderColor: const Color(0xFF12B8F7),
                      fontSize: 18.sp,
                    ),

                    SizedBox(height: 24.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn’t receive the code?',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Resend OTP',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.heroButton,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 52.h),

                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.cardBorder)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.cardBorder)),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    Container(
                      width: double.infinity,
                      height: 58.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.cardBorder),
                        color: AppColors.card.withValues(alpha: 0.45),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.heroButton,
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Change email address',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final bool isActive;

  const _OtpBox({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 65.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isActive ? AppColors.heroButton : AppColors.cardBorder,
          width: 1.3,
        ),
        color: AppColors.card.withValues(alpha: 0.45),
      ),
      child: Center(
        child: isActive
            ? Container(
                width: 2.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: AppColors.heroButton,
                  borderRadius: BorderRadius.circular(100.r),
                ),
              )
            : null,
      ),
    );
  }
}
