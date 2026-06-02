import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'application/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _otpLength = 6;
  static const _otpDuration = Duration(minutes: 10);
  static const _resendCooldown = Duration(seconds: 30);

  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  late DateTime _expiresAt;
  late DateTime _resendAvailableAt;
  Duration _remaining = _otpDuration;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;

  bool get _canVerify {
    return _otpController.text.length == _otpLength &&
        _remaining > Duration.zero &&
        !_isVerifying;
  }

  bool get _canResend {
    return DateTime.now().isAfter(_resendAvailableAt) &&
        !_isResending &&
        !_isVerifying;
  }

  String get _resendText {
    final cooldown = _resendAvailableAt.difference(DateTime.now());
    if (cooldown > Duration.zero) {
      return 'Resend in ${cooldown.inSeconds}s';
    }

    return _isResending ? 'Resending...' : 'Resend OTP';
  }

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_handleOtpFocusChanged);
    _resetTimers();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final nextRemaining = _expiresAt.difference(DateTime.now());
      setState(() {
        _remaining = nextRemaining.isNegative ? Duration.zero : nextRemaining;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpFocusNode.removeListener(_handleOtpFocusChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _handleOtpFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != _otpLength) {
      _showMessage('Enter the 6-digit code');
      return;
    }

    if (_remaining == Duration.zero) {
      _showMessage('This code has expired. Request a new one.');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final session = await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(email: widget.email, otp: otp);

      if (!mounted) return;

      _showMessage('Signed in as ${session.user.email}');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isResending = true);

    try {
      await ref.read(authRepositoryProvider).requestOtp(widget.email);

      if (!mounted) return;

      _otpController.clear();
      _resetTimers();
      _otpFocusNode.requestFocus();
      _showMessage('A new code has been sent');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _resetTimers() {
    final now = DateTime.now();
    _expiresAt = now.add(_otpDuration);
    _resendAvailableAt = now.add(_resendCooldown);
    _remaining = _otpDuration;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formattedRemaining() {
    final totalSeconds = _remaining.inSeconds.clamp(0, _otpDuration.inSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final otp = _otpController.text;

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
                      'to ${widget.email}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: 40.h),

                    GestureDetector(
                      onTap: _otpFocusNode.requestFocus,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 356),
                        child: SizedBox(
                          height: 68.h,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.01,
                                  child: TextField(
                                    controller: _otpController,
                                    focusNode: _otpFocusNode,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.oneTimeCode,
                                    ],
                                    maxLength: _otpLength,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(
                                        _otpLength,
                                      ),
                                    ],
                                    style: const TextStyle(
                                      color: Colors.transparent,
                                    ),
                                    cursorColor: Colors.transparent,
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: (_) => _verifyOtp(),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(_otpLength, (index) {
                                    final digit = index < otp.length
                                        ? otp[index]
                                        : null;
                                    final isActive =
                                        _otpFocusNode.hasFocus &&
                                        index == otp.length &&
                                        otp.length < _otpLength;

                                    return _OtpBox(
                                      digit: digit,
                                      isActive: isActive,
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            text: _formattedRemaining(),
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
                      text: _isVerifying ? 'Verifying...' : 'Verify OTP',
                      height: 50.h,
                      borderRadius: AppRadius.sm,
                      backgroundColor: _canVerify
                          ? const Color(0xFF12B8F7)
                          : AppColors.cardBorder,
                      borderColor: _canVerify
                          ? const Color(0xFF12B8F7)
                          : AppColors.cardBorder,
                      fontSize: 18.sp,
                      icon: _isVerifying
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : null,
                      onPressed: _canVerify ? _verifyOtp : null,
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
                        GestureDetector(
                          onTap: _canResend ? _resendOtp : null,
                          child: Text(
                            _resendText,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: _canResend
                                  ? AppColors.heroButton
                                  : AppColors.textSecondary,
                            ),
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

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
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
  final String? digit;
  final bool isActive;

  const _OtpBox({required this.digit, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final width = 48.w.clamp(42.0, 54.0).toDouble();
    final height = 65.h.clamp(58.0, 70.0).toDouble();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isActive ? AppColors.heroButton : AppColors.cardBorder,
          width: 1.3,
        ),
        color: AppColors.card.withValues(alpha: 0.45),
      ),
      child: Center(
        child: digit != null
            ? Text(
                digit!,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              )
            : isActive
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
