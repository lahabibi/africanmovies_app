import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class AppTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      maxLines: maxLines,
      onChanged: onChanged,
      enabled: enabled,
      style: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,

        prefixIcon: prefixIcon,

        suffixIcon: suffixIcon,

        filled: true,
        fillColor: AppColors.card,

        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),

        hintStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}
