import 'package:africanmovies/features/profile/widgets/device_card.dart';
import 'package:africanmovies/features/profile/widgets/section_title.dart';
import 'package:africanmovies/features/profile/widgets/security_info_card.dart';
import 'package:africanmovies/shared/widgets/app_screen_header_with_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/responsive.dart';
import '../auth/application/auth_device_providers.dart';
import '../auth/domain/auth_device_session.dart';

class LoggedInDevicesScreen extends ConsumerStatefulWidget {
  const LoggedInDevicesScreen({super.key});

  @override
  ConsumerState<LoggedInDevicesScreen> createState() {
    return _LoggedInDevicesScreenState();
  }
}

class _LoggedInDevicesScreenState extends ConsumerState<LoggedInDevicesScreen> {
  String? _signingOutDeviceId;
  bool _isSigningOutOthers = false;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final devicesState = ref.watch(authDevicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8.h,
                horizontalPadding,
                12.h,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.formMaxWidth(context),
                  ),
                  child: const AppScreenHeaderWithTitle(
                    title: 'Logged in devices',
                  ),
                ),
              ),
            ),
            Expanded(
              child: devicesState.when(
                loading: () => const _DevicesLoadingState(),
                error: (error, _) {
                  return _DevicesErrorState(
                    message: _messageFor(error),
                    onRetry: () => ref.invalidate(authDevicesProvider),
                  );
                },
                data: (devices) => _DevicesContent(
                  devices: devices,
                  signingOutDeviceId: _signingOutDeviceId,
                  isSigningOutOthers: _isSigningOutOthers,
                  onSignOutDevice: _signOutDevice,
                  onSignOutOtherDevices: _signOutOtherDevices,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOutDevice(AuthDeviceSession device) async {
    final confirmed = await _confirmAction(
      title: 'Sign out this device?',
      message:
          'This will remove access from ${device.displayName}. You can sign in again anytime with email OTP.',
      actionText: 'Sign Out',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOutDeviceId = device.id);

    try {
      await ref.read(authRepositoryProvider).logoutDevice(device.id);
      ref.invalidate(authDevicesProvider);
      await ref.read(authDevicesProvider.future);
      if (!mounted) return;
      _showMessage('${device.displayName} was signed out.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _signingOutDeviceId = null);
    }
  }

  Future<void> _signOutOtherDevices() async {
    final confirmed = await _confirmAction(
      title: 'Sign out other devices?',
      message:
          'This will sign you out on every other device using your account. This phone will stay signed in.',
      actionText: 'Sign Out Others',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOutOthers = true);

    try {
      await ref.read(authRepositoryProvider).logoutOtherDevices();
      ref.invalidate(authDevicesProvider);
      await ref.read(authDevicesProvider.future);
      if (!mounted) return;
      _showMessage('Other devices were signed out.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _isSigningOutOthers = false);
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 14.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                actionText,
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;

    return error.toString();
  }
}

class _DevicesContent extends StatelessWidget {
  final List<AuthDeviceSession> devices;
  final String? signingOutDeviceId;
  final bool isSigningOutOthers;
  final ValueChanged<AuthDeviceSession> onSignOutDevice;
  final VoidCallback onSignOutOtherDevices;

  const _DevicesContent({
    required this.devices,
    required this.signingOutDeviceId,
    required this.isSigningOutOthers,
    required this.onSignOutDevice,
    required this.onSignOutOtherDevices,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final currentDevices = devices.where((device) => device.isCurrent).toList();
    final otherDevices = devices.where((device) => !device.isCurrent).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.formMaxWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DevicesIntro(),
              SizedBox(height: 14.h),
              SectionTitle('THIS DEVICE'),
              SizedBox(height: 10.h),
              if (currentDevices.isEmpty)
                const _EmptyDevicesCard(
                  text: 'This device will appear here after the next refresh.',
                )
              else
                ...currentDevices.map(
                  (device) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: DeviceCard(device: device),
                  ),
                ),
              SizedBox(height: 2.h),
              SectionTitle('OTHER DEVICES'),
              SizedBox(height: 12.h),
              if (otherDevices.isEmpty)
                const _EmptyDevicesCard(
                  text: 'No other devices are signed in right now.',
                )
              else
                ...otherDevices.map(
                  (device) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: DeviceCard(
                      device: device,
                      isBusy: signingOutDeviceId == device.id,
                      onSignOut: () => onSignOutDevice(device),
                    ),
                  ),
                ),
              SizedBox(height: 16.h),
              const SecurityInfoCard(),
              SizedBox(height: 26.h),
              SizedBox(
                width: double.infinity,
                height: 58.h,
                child: ElevatedButton.icon(
                  onPressed: isSigningOutOthers || otherDevices.isEmpty
                      ? null
                      : onSignOutOtherDevices,
                  icon: isSigningOutOthers
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.logout_rounded,
                          size: 26.sp,
                          color: Colors.white,
                        ),
                  label: Text(
                    isSigningOutOthers
                        ? 'Signing out...'
                        : 'Sign out of other devices',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.heroButton,
                    disabledBackgroundColor: AppColors.heroButton.withValues(
                      alpha: .55,
                    ),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevicesIntro extends StatelessWidget {
  const _DevicesIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 92.w,
            height: 92.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .08),
            ),
            child: Center(
              child: Container(
                width: 62.w,
                height: 62.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: .10),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 38.sp,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            'Manage your devices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Text(
            'You are signed in to AfricanMovies on the\ndevices below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDevicesCard extends StatelessWidget {
  final String text;

  const _EmptyDevicesCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .62),
          fontSize: 13.sp,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DevicesLoadingState extends StatelessWidget {
  const _DevicesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 30.w,
        height: 30.w,
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _DevicesErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DevicesErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.formMaxWidth(context),
          ),
          child: Column(
            children: [
              const _DevicesIntro(),
              SizedBox(height: 28.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .035),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 34.sp,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(
                        'Try Again',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
