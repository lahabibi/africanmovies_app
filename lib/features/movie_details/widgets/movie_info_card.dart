import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../movies/domain/movie.dart';

class MovieInfoCard extends StatelessWidget {
  final Movie movie;

  const MovieInfoCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final cast = movie.actors
        .map((actor) => actor.trim())
        .where((actor) => actor.isNotEmpty)
        .take(3)
        .join(',\n');

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _InfoItem(title: 'Genre', value: _value(movie.genre)),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _InfoItem(title: 'Cast', value: _value(cast)),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _InfoItem(title: 'Audio', value: _value(movie.language)),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _InfoItem(
                title: 'Country',
                value: _value(movie.countryName),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _value(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? 'N/A' : trimmedValue;
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const _InfoItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.heroButton,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(width: 1.w, height: 72.h, color: AppColors.cardBorder),
    );
  }
}
