import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';

class AppScreenHeaderWithTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  final Widget? trailing;

  const AppScreenHeaderWithTitle({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          GestureDetector(
            onTap: onBackTap ?? () => Navigator.pop(context),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          )
        else
          SizedBox(width: 24.w),

        Expanded(
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        SizedBox(
          width: 42.w,
          height: 42.w,
          child: trailing ?? const SizedBox(),
        ),
      ],
    );
  }
}
