import 'package:africanmovies/features/auth/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_text_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      _showMessage('Enter a valid email address');
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(authRepositoryProvider).requestOtp(email);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  bool _isValidEmail(String value) {
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailPattern.hasMatch(value);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);

    return AppScaffold(
      usePadding: false,
      child: Stack(
        children: [
          Positioned(
            left: -20.w,
            right: -20.w,
            bottom: -18.h,
            child: SizedBox(
              height: 330.h,
              child: Stack(
                children: [
                  Positioned(
                    left: 8.w,
                    bottom: 30.h,
                    child: Transform.rotate(
                      angle: -0.10,
                      child: _PosterTile(
                        image: AppAssets.poster1,
                        width: 130.w,
                        height: 190.h,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 140.w,
                    bottom: 48.h,
                    child: Transform.rotate(
                      angle: 0.08,
                      child: _PosterTile(
                        image: AppAssets.poster2,
                        width: 140.w,
                        height: 200.h,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4.w,
                    bottom: 22.h,
                    child: Transform.rotate(
                      angle: 0.12,
                      child: _PosterTile(
                        image: AppAssets.poster3,
                        width: 132.w,
                        height: 194.h,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withValues(alpha: 0.02),
                            AppColors.background.withValues(alpha: 0.42),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.formMaxWidth(context),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 360.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.h),

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

                        SizedBox(height: 76.h),

                        Center(
                          child: Image.asset(AppAssets.logo, height: 44.h),
                        ),

                        SizedBox(height: 42.h),

                        Center(
                          child: Text(
                            'Welcome to AfricanMovies',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        Center(
                          child: Text(
                            'Enter your email address and we’ll send\nyou a one-time passcode.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.sp,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        SizedBox(height: 18.h),

                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 14.h),

                        AppTextField(
                          hintText: 'Enter your email address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_isSending,
                          onChanged: (_) => setState(() {}),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: 20.h),

                        AppButton(
                          text: _isSending ? 'Sending...' : 'Send OTP',
                          height: 50.h,
                          borderRadius: AppRadius.sm,
                          backgroundColor: const Color(0xFF12B8F7),
                          borderColor: const Color(0xFF12B8F7),
                          fontSize: 18.sp,
                          icon: _isSending
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                          onPressed: _isSending ? null : _sendOtp,
                        ),

                        SizedBox(height: 20.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.heroButton,
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Flexible(
                              child: Text(
                                'We’ll never share your email with anyone.',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  final String image;
  final double width;
  final double height;

  const _PosterTile({
    required this.image,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}
