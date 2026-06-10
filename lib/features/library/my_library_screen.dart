import 'package:africanmovies/core/network/api_exception.dart';
import 'package:africanmovies/features/home/widgets/home_header.dart';
import 'package:africanmovies/features/library/widgets/library_continue_card.dart';
import 'package:africanmovies/features/library/widgets/library_movie_card.dart';
import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/player/application/player_providers.dart';
import 'package:africanmovies/features/player/movie_player_screen.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';

class MyLibraryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBrowseMovies;

  const MyLibraryScreen({super.key, this.onBrowseMovies});

  @override
  ConsumerState<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends ConsumerState<MyLibraryScreen> {
  String? _openingOrderId;

  Future<void> _refreshLibrary() async {
    await forceRefreshHomeData(ref);
  }

  Future<void> _openMoviePlayer(HomeOrder order) async {
    final movie = order.movie;
    if (movie == null || _openingOrderId != null) return;

    final orderId = order.id.isNotEmpty ? order.id : movie.id;
    setState(() => _openingOrderId = orderId);

    try {
      final playback = await ref
          .read(playerRepositoryProvider)
          .requestMoviePlayback(movie.id);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MoviePlayerScreen(playback: playback),
        ),
      );

      if (!mounted) return;
      ref.invalidate(homeDataProvider);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _openingOrderId = null);
      }
    }
  }

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);
    final libraryData = ref.watch(homeDataProvider);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: libraryData.when(
              data: (data) => _LibraryContent(
                data: data,
                openingOrderId: _openingOrderId,
                onRefresh: _refreshLibrary,
                onPlayOrder: _openMoviePlayer,
                onWatchAgain: _openMovieDetails,
                onBrowseMovies: widget.onBrowseMovies,
              ),
              loading: _LibraryLoadingView.new,
              error: (error, _) => _LibraryErrorView(
                message: _messageFor(error),
                onRetry: () => ref.invalidate(homeDataProvider),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: headerHeight, child: const HomeHeader()),
          ),
        ],
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  final HomeData data;
  final String? openingOrderId;
  final Future<void> Function() onRefresh;
  final ValueChanged<HomeOrder> onPlayOrder;
  final ValueChanged<Movie> onWatchAgain;
  final VoidCallback? onBrowseMovies;

  const _LibraryContent({
    required this.data,
    required this.openingOrderId,
    required this.onRefresh,
    required this.onPlayOrder,
    required this.onWatchAgain,
    this.onBrowseMovies,
  });

  @override
  Widget build(BuildContext context) {
    final continueWatchingOrders = data.continueWatchingOrders;
    final expiringSoonOrders = data.expiringSoonOrders;
    final expiringSoonMovieIds = expiringSoonOrders
        .map((order) => order.movieId)
        .toSet();
    final activeOrders = data.activeLibraryOrders
        .where((order) => !expiringSoonMovieIds.contains(order.movieId))
        .toList();
    final expiredOrders = data.expiredLibraryOrders;
    final hasLibraryMovies =
        data.activeLibraryOrders.isNotEmpty || expiredOrders.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            _LibraryHeader(
              purchasedCount: data.purchasedMovieCount,
              activeCount: activeOrders.length,
              expiredCount: expiredOrders.length,
            ),
            SizedBox(height: 14.h),
            if (!hasLibraryMovies)
              _LibraryEmptyState(onBrowseMovies: onBrowseMovies)
            else ...[
              if (continueWatchingOrders.isNotEmpty) ...[
                _ContinueWatchingLibrarySection(
                  orders: continueWatchingOrders,
                  onPlayOrder: onPlayOrder,
                ),
                SizedBox(height: 14.h),
              ],
              if (activeOrders.isNotEmpty) ...[
                _LibraryMovieSection(
                  title: 'Active Access',
                  orders: activeOrders,
                  openingOrderId: openingOrderId,
                  isExpiredSection: false,
                  onPlayOrder: onPlayOrder,
                  onWatchAgain: onWatchAgain,
                ),
                SizedBox(height: 4.h),
              ],
              if (expiringSoonOrders.isNotEmpty) ...[
                _LibraryMovieSection(
                  title: 'Expiring Soon',
                  orders: expiringSoonOrders,
                  openingOrderId: openingOrderId,
                  isExpiredSection: false,
                  onPlayOrder: onPlayOrder,
                  onWatchAgain: onWatchAgain,
                ),
                SizedBox(height: 4.h),
              ],
              if (expiredOrders.isNotEmpty)
                _LibraryMovieSection(
                  title: 'Expired Movies',
                  orders: expiredOrders,
                  openingOrderId: openingOrderId,
                  isExpiredSection: true,
                  onPlayOrder: onPlayOrder,
                  onWatchAgain: onWatchAgain,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final int purchasedCount;
  final int activeCount;
  final int expiredCount;

  const _LibraryHeader({
    required this.purchasedCount,
    required this.activeCount,
    required this.expiredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Library',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Purchased movies available for streaming.',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _LibraryStatChip(
              icon: Icons.confirmation_number_outlined,
              label:
                  '$purchasedCount ${purchasedCount == 1 ? 'Movie' : 'Movies'}',
            ),
            _LibraryStatChip(
              icon: Icons.play_circle_outline_rounded,
              label: '$activeCount Active',
              color: AppColors.heroButton,
            ),
            if (expiredCount > 0)
              _LibraryStatChip(
                icon: Icons.history_rounded,
                label: '$expiredCount Expired',
                color: AppColors.warning,
              ),
          ],
        ),
      ],
    );
  }
}

class _LibraryStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LibraryStatChip({
    required this.icon,
    required this.label,
    this.color = AppColors.heroButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingLibrarySection extends StatelessWidget {
  final List<HomeOrder> orders;
  final ValueChanged<HomeOrder> onPlayOrder;

  const _ContinueWatchingLibrarySection({
    required this.orders,
    required this.onPlayOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Continue Watching'),
        SizedBox(height: 12.h),
        SizedBox(
          height: 260.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: orders.length,
            separatorBuilder: (_, _) => SizedBox(width: 10.w),
            itemBuilder: (_, index) {
              final order = orders[index];
              final movie = order.movie;
              if (movie == null) return const SizedBox.shrink();

              return LibraryContinueCard(
                image: movie.displayPosterUrl,
                progress: order.progress,
                progressText: _progressText(order),
                timeLeft: _timeLeft(order),
                expiryText: _expiryText(order),
                onTap: () => onPlayOrder(order),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LibraryMovieSection extends StatelessWidget {
  final String title;
  final List<HomeOrder> orders;
  final String? openingOrderId;
  final bool isExpiredSection;
  final ValueChanged<HomeOrder> onPlayOrder;
  final ValueChanged<Movie> onWatchAgain;

  const _LibraryMovieSection({
    required this.title,
    required this.orders,
    required this.openingOrderId,
    required this.isExpiredSection,
    required this.onPlayOrder,
    required this.onWatchAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(height: 12.h),
        SizedBox(
          height: 230.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: orders.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (_, index) {
              final order = orders[index];
              final movie = order.movie;
              if (movie == null) return const SizedBox.shrink();

              return LibraryMovieCard(
                image: movie.displayPosterUrl,
                expiryText: _expiryText(order),
                actionText: isExpiredSection
                    ? 'Watch Again'
                    : order.currentTime > 0
                    ? 'Resume'
                    : 'Watch Now',
                expiryBadgeText: _expiryBadgeText(order),
                onTap: isExpiredSection
                    ? () => onWatchAgain(movie)
                    : () => onPlayOrder(order),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  final VoidCallback? onBrowseMovies;

  const _LibraryEmptyState({this.onBrowseMovies});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            color: AppColors.heroButton,
            size: 38.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'Your library is empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            'Movies you purchase or claim will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              height: 1.35,
            ),
          ),
          if (onBrowseMovies != null) ...[
            SizedBox(height: 18.h),
            SizedBox(
              height: 42.h,
              child: ElevatedButton.icon(
                onPressed: onBrowseMovies,
                icon: Icon(Icons.explore_outlined, size: 17.sp),
                label: Text(
                  'Browse Movies',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.heroButton,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LibraryLoadingView extends StatelessWidget {
  const _LibraryLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 30.w,
        height: 30.w,
        child: const CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _LibraryErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LibraryErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
              size: 42.sp,
            ),
            SizedBox(height: 14.h),
            Text(
              'Unable to load library',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
                height: 1.35,
              ),
            ),
            SizedBox(height: 18.h),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _progressText(HomeOrder order) {
  final percent = (order.progress * 100).clamp(0, 100).round();
  return '$percent% watched';
}

String _timeLeft(HomeOrder order) {
  final movie = order.movie;
  if (movie == null || movie.duration <= 0) return 'Resume';

  final totalSeconds = (movie.duration * 60).round();
  final remainingSeconds = totalSeconds - order.currentTime.round();

  if (remainingSeconds <= 0) return 'Almost done';

  return '${_formatDuration(remainingSeconds)} left';
}

String _expiryText(HomeOrder order) {
  final expiryDate = order.expiryDate;
  if (expiryDate == null) return 'No expiry date';

  final now = DateTime.now();
  final remaining = expiryDate.difference(now);

  if (remaining.isNegative || remaining == Duration.zero) {
    return 'Expired ${_formatShortDate(expiryDate)}';
  }

  if (remaining.inHours < 24) {
    final hours = remaining.inHours <= 0 ? 1 : remaining.inHours;
    return 'Expires in ${hours}h';
  }

  final days = remaining.inDays;
  if (days <= 1) return 'Expires tomorrow';

  return 'Expires in $days days';
}

String? _expiryBadgeText(HomeOrder order) {
  if (order.isExpired) return 'Expired';

  final expiryDate = order.expiryDate;
  if (expiryDate == null) return null;

  final remaining = expiryDate.difference(DateTime.now());
  if (remaining.isNegative || remaining >= const Duration(days: 3)) return null;

  if (remaining.inHours < 24) {
    final hours = remaining.inHours <= 0 ? 1 : remaining.inHours;
    return '${hours}h left';
  }

  final days = remaining.inDays <= 0 ? 1 : remaining.inDays;
  return '$days ${days == 1 ? 'day' : 'days'} left';
}

String _formatDuration(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';

  return '${minutes <= 0 ? 1 : minutes}m';
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}';
}
