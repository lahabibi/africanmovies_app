import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/network_status.dart';
import '../../core/providers/network_providers.dart';
import '../../features/movies/application/movie_providers.dart';

class NetworkGate extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkGate({super.key, required this.child});

  @override
  ConsumerState<NetworkGate> createState() => _NetworkGateState();
}

class _NetworkGateState extends ConsumerState<NetworkGate> {
  static const _unstableConnectionDelay = Duration(seconds: 6);

  Timer? _unstableConnectionTimer;
  bool _showConnectionBanner = false;
  bool _hadUnstableConnection = false;

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
      _hadUnstableConnection = true;
      _scheduleConnectionBanner();
      return;
    }

    if (nextStatus == NetworkStatus.online) {
      final wasOffline =
          _hadUnstableConnection ||
          _showConnectionBanner ||
          previousStatus == NetworkStatus.offline ||
          previous?.hasError == true;

      _hadUnstableConnection = false;
      _unstableConnectionTimer?.cancel();
      _unstableConnectionTimer = null;
      _setConnectionBannerVisible(false);

      if (wasOffline) {
        ref.invalidate(homeDataProvider);
        ref.invalidate(movieSearchProvider);
      }
    }
  }

  void _scheduleConnectionBanner() {
    if (_showConnectionBanner || _unstableConnectionTimer?.isActive == true) {
      return;
    }

    _unstableConnectionTimer = Timer(_unstableConnectionDelay, () {
      _unstableConnectionTimer = null;
      if (!_hadUnstableConnection) return;
      _setConnectionBannerVisible(true);
    });
  }

  void _setConnectionBannerVisible(bool visible) {
    if (_showConnectionBanner == visible) return;

    if (!mounted) {
      _showConnectionBanner = visible;
      return;
    }

    setState(() => _showConnectionBanner = visible);
  }

  @override
  void dispose() {
    _unstableConnectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkStatusProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_showConnectionBanner,
            child: AnimatedSlide(
              offset: _showConnectionBanner ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showConnectionBanner ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: SafeArea(
                  bottom: false,
                  child: _ConnectionBanner(
                    isChecking: networkState.isLoading,
                    onRetry: () => ref.invalidate(networkStatusProvider),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final bool isChecking;
  final VoidCallback onRetry;

  const _ConnectionBanner({required this.isChecking, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFF07111E).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: isChecking
                    ? Padding(
                        padding: EdgeInsets.all(8.w),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.wifi_off_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isChecking
                          ? 'Checking connection...'
                          : 'Connection is unstable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.sp,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Showing saved data when available.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Retry connection',
                onPressed: isChecking ? null : onRetry,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isChecking
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  size: 21.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
