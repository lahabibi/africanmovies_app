import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';

class StartupSplash extends StatefulWidget {
  final Widget child;

  const StartupSplash({super.key, required this.child});

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1300);

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _accentOpacity;
  late final Animation<double> _exitOpacity;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showSplash = false);
        }
      });

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
      ),
    );
    _accentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.72, curve: Curves.easeOutCubic),
    );
    _exitOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 72),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 28,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) return widget.child;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenWidth * 0.78).clamp(240.0, 320.0).toDouble();

    return FadeTransition(
      opacity: _exitOpacity,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -110,
              right: -100,
              child: _SplashGlow(
                size: 280,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -95,
              child: _SplashGlow(
                size: 260,
                color: AppColors.deepBlue.withValues(alpha: 0.14),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        AppAssets.splashLogo,
                        width: logoWidth,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _accentOpacity,
                    child: const _SplashAccent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _SplashGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _SplashAccent extends StatelessWidget {
  const _SplashAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [AppColors.deepBlue, AppColors.primary],
        ),
      ),
    );
  }
}
