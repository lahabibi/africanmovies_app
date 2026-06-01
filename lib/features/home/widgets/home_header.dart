import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';


class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppAssets.logo,
          height: 32.h,
        ),
        const Spacer(),
        _HeaderIcon(icon: AppAssets.search),
        SizedBox(width: 12.w),
        _HeaderIcon(icon: AppAssets.notification),
        SizedBox(width: 12.w),
        Container(
          width: 36.w,
          height: 36.w,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Image.asset(
            AppAssets.profile,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}


class _HeaderIcon extends StatelessWidget {
  final String icon;

  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Image.asset(
          icon,
          width: 19.w,
          height: 19.w,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}