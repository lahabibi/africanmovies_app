import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_screen_header.dart';

class AboutAfricanMoviesScreen extends StatelessWidget {
  const AboutAfricanMoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20.h),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 18.h),
                      Text(
                        'About African Movies',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Our mission, our story, and what drives us to bring African stories to the world.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 28.h),

                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: const [
                            _AboutItem(
                              icon: Icons.movie_creation_outlined,
                              title: 'Our Mission',
                              description:
                                  'To entertain, inspire, and connect audiences around the world through authentic African stories and cinematic excellence.',
                            ),
                            _Divider(),
                            _AboutItem(
                              icon: Icons.favorite_border_rounded,
                              title: 'Our Vision',
                              description:
                                  'To be the leading streaming platform for African movies, empowering creators and celebrating the richness of African culture.',
                            ),
                            _Divider(),
                            _AboutItem(
                              icon: Icons.groups_outlined,
                              title: 'Our Values',
                              description:
                                  'Authenticity, Diversity, Creativity, Integrity and Community.',
                            ),
                            _Divider(),
                            _AboutItem(
                              icon: Icons.star_border_rounded,
                              title: 'What We Offer',
                              description:
                                  'A wide collection of African movies and shows across different genres and languages. New content added regularly for your entertainment.',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const _AboutItem(
                          icon: Icons.verified_user_outlined,
                          title: 'Built for You',
                          description:
                              'AfricanMovies is designed with you in mind. We’re committed to providing good streaming experience with quality content, anywhere and anytime.',
                        ),
                      ),

                      SizedBox(height: 46.h),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              '© 2026 AfricanMovies. All rights reserved.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: headerHeight,
              child: const AppScreenHeader(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _AboutItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.heroButton, size: 32.sp),
        SizedBox(width: 18.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Divider(color: AppColors.cardBorder),
    );
  }
}
