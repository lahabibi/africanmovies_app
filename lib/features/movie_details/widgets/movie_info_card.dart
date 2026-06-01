import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';

class MovieInfoCard extends StatelessWidget {
  const MovieInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          children: const [
            Expanded(
              child: _InfoItem(title: 'Genre', value: 'Drama,\nThriller'),
            ),
            _VerticalDivider(),
            Expanded(
              child: _InfoItem(
                title: 'Cast',
                value: 'Funke Akindele,\nKanayo O. Kanayo',
              ),
            ),
            _VerticalDivider(),
            Expanded(
              child: _InfoItem(title: 'Audio', value: 'English,\nYoruba'),
            ),
            _VerticalDivider(),
            Expanded(
              child: _InfoItem(title: 'Country', value: 'Nigeria'),
            ),
          ],
        ),
      ),
    );
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
