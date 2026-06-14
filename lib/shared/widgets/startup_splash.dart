import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';

class StartupSplash extends StatefulWidget {
  final Widget child;

  const StartupSplash({super.key, required this.child});

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  static const _duration = Duration(milliseconds: 900);

  Timer? _timer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_duration, () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) return widget.child;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenWidth * 0.78).clamp(240.0, 320.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image.asset(
          AppAssets.splashLogo,
          width: logoWidth,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
