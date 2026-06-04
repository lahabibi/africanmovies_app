import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/network_status.dart';
import '../../core/providers/network_providers.dart';
import '../../core/utils/responsive.dart';
import '../../features/movies/application/movie_providers.dart';
import 'app_button.dart';
import 'app_scaffold.dart';

class NetworkGate extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkGate({super.key, required this.child});

  @override
  ConsumerState<NetworkGate> createState() => _NetworkGateState();
}

class _NetworkGateState extends ConsumerState<NetworkGate> {
  bool _showOffline = false;

  @override
  void initState() {
    super.initState();

    ref.listenManual<AsyncValue<NetworkStatus>>(
      networkStatusProvider,
      _handleNetworkStatusChanged,
      fireImmediately: true,
    );
  }

  void _handleNetworkStatusChanged(
    AsyncValue<NetworkStatus>? previous,
    AsyncValue<NetworkStatus> next,
  ) {
    final previousStatus = previous?.value;
    final nextStatus = next.value;

    if (next.hasError || nextStatus == NetworkStatus.offline) {
      _setOfflineVisible(true);
      return;
    }

    if (nextStatus == NetworkStatus.online) {
      final wasOffline =
          _showOffline ||
          previousStatus == NetworkStatus.offline ||
          previous?.hasError == true;

      _setOfflineVisible(false);

      if (wasOffline) {
        ref.invalidate(homeDataProvider);
        ref.invalidate(movieSearchProvider);
      }
    }
  }

  void _setOfflineVisible(bool visible) {
    if (_showOffline == visible) return;

    if (!mounted) {
      _showOffline = visible;
      return;
    }

    setState(() => _showOffline = visible);
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkStatusProvider);
    final status = networkState.value;
    final showOffline =
        _showOffline ||
        networkState.hasError ||
        status == NetworkStatus.offline;

    if (!showOffline) return widget.child;

    return _NoInternetScreen(
      isChecking: networkState.isLoading,
      onRetry: () {
        _setOfflineVisible(true);
        ref.invalidate(networkStatusProvider);
      },
    );
  }
}

class _NoInternetScreen extends StatelessWidget {
  final bool isChecking;
  final VoidCallback onRetry;

  const _NoInternetScreen({required this.isChecking, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final iconSize = isTablet ? 36.0 : 30.sp;
    final cardWidth = isTablet ? 460.0 : double.infinity;

    return AppScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cardWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.logo,
                height: isTablet ? 64 : 52.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: isTablet ? 38 : 32.h),
              Container(
                width: isTablet ? 82 : 72.w,
                height: isTablet ? 82 : 72.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: iconSize,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20.h),
              Text(
                'No internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 26 : 22.sp,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Check your Wi-Fi or mobile data. We will refresh automatically once you are back online.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: isTablet ? 28 : 24.h),
              AppButton(
                text: isChecking ? 'Checking...' : 'Try Again',
                width: isTablet ? 220 : 180.w,
                height: isTablet ? 48 : 44.h,
                borderRadius: AppRadius.sm,
                onPressed: isChecking ? null : onRetry,
                icon: isChecking
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textPrimary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
