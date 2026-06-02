import 'package:africanmovies/features/auth/auth_screen.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_hero.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_info_card.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_purchase_button.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_small_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/section_movie_card.dart';

class MovieDetailsScreen extends ConsumerWidget {
  const MovieDetailsScreen({super.key});

  static const _relatedMovies = [
    AppAssets.poster6,
    AppAssets.poster7,
    AppAssets.poster8,
    AppAssets.poster9,
    AppAssets.poster10,
  ];

  bool _requireAuth(BuildContext context, WidgetRef ref) {
    final hasSession = ref.read(authControllerProvider).asData?.value != null;
    if (hasSession) return true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MovieHero(),
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: MoviePurchaseButton(
                              price: '\$0.99',
                              onTap: () {
                                _requireAuth(context, ref);
                              },
                            ),
                          ),
                          SizedBox(width: 6.w),
                          const MovieSmallAction(
                            icon: Icons.smart_display_outlined,
                            label: 'Trailer',
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: Icons.bookmark_add_outlined,
                            label: 'watchlist',
                            onTap: () {
                              _requireAuth(context, ref);
                            },
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: Icons.favorite_border_rounded,
                            label: 'Favorite',
                            onTap: () {
                              _requireAuth(context, ref);
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      Text(
                        'When a widowed mother refuses to sell her late husband’s land '
                        'to a powerful businessman, she becomes the target of a dark '
                        'conspiracy that tests her faith, courage and will to survive.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        children: [
                          Text(
                            'Read More',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.heroButton,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.heroButton,
                            size: 18.sp,
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      const MovieInfoCard(),

                      SizedBox(height: 14.h),

                      const SectionHeader(
                        title: 'More Like This',
                        actionText: 'See All »',
                      ),

                      SizedBox(height: 12.h),

                      SizedBox(
                        height: 168.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _relatedMovies.length,
                          separatorBuilder: (_, _) => SizedBox(width: 8.w),
                          itemBuilder: (_, index) {
                            return SectionMovieCard(
                              image: _relatedMovies[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
