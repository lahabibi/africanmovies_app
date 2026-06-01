import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

enum AppButtonVariant {
  primary,
  outline,
  danger,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final double? height;
  final double? width;
  final double? fontSize;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.height,
    this.width,
    this.fontSize,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    final isDanger = variant == AppButtonVariant.danger;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppRadius.lg,
        ),
        child: Container(
          height: height ?? AppSpacing.buttonHeight,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isPrimary
                    ? AppColors.primary
                    : isDanger
                    ? AppColors.danger
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppRadius.lg,
            ),
            border: Border.all(
              color: borderColor ??
                  (isPrimary
                      ? AppColors.primary
                      : isDanger
                      ? AppColors.danger
                      : AppColors.cardBorder),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: 8.w),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize ?? 15.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}