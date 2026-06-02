import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;

  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.color,
  });

  bool get _isNetworkImage {
    return source.startsWith('http://') || source.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const _ImageFallback();

    if (!_isNetworkImage) {
      return Image.asset(source, fit: fit, alignment: alignment, color: color);
    }

    return Image.network(
      source,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => const _ImageFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return const _ImageFallback(showProgress: true);
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final bool showProgress;

  const _ImageFallback({this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Center(
        child: showProgress
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.movie_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
