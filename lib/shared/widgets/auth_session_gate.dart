import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/providers/app_providers.dart';

class AuthSessionGate extends ConsumerStatefulWidget {
  final Widget child;

  const AuthSessionGate({super.key, required this.child});

  @override
  ConsumerState<AuthSessionGate> createState() => _AuthSessionGateState();
}

class _AuthSessionGateState extends ConsumerState<AuthSessionGate> {
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();

    ref.listenManual<String?>(
      authSessionExpiredMessageProvider,
      _handleSessionExpiredMessage,
      fireImmediately: true,
    );
  }

  void _handleSessionExpiredMessage(String? previous, String? next) {
    if (next == null || next.isEmpty || _isShowingDialog) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSessionExpiredDialog(next);
    });
  }

  Future<void> _showSessionExpiredDialog(String message) async {
    if (!mounted || _isShowingDialog) return;

    _isShowingDialog = true;
    ref.read(authSessionExpiredMessageProvider.notifier).clear();

    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            title: Text(
              'Session expired',
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
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    color: AppColors.heroButton,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        ref.read(authSessionExpiredMessageProvider.notifier).clear();
        _isShowingDialog = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
