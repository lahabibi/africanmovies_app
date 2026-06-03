import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/notifications/application/notification_providers.dart';
import 'package:africanmovies/features/notifications/domain/in_app_notification.dart';
import 'package:africanmovies/shared/widgets/app_image.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    InAppNotification notification,
  ) async {
    await ref
        .read(notificationsControllerProvider.notifier)
        .markAsRead(notification.id);

    if (!context.mounted) return;

    final movie = _movieForNotification(ref, notification);
    if (movie == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  Movie? _movieForNotification(WidgetRef ref, InAppNotification notification) {
    final movieId = notification.movieId;
    if (movieId == null || movieId.isEmpty) return null;

    final homeData = ref.read(homeDataProvider).asData?.value;
    if (homeData == null) return null;

    for (final movie in homeData.movies) {
      if (movie.id == movieId) return movie;
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = Responsive.headerHeight(context);
    final notificationsState = ref.watch(notificationsControllerProvider);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: notificationsState.when(
                  data: (notifications) => _NotificationsContent(
                    notifications: notifications,
                    onNotificationTap: (notification) {
                      _handleNotificationTap(context, ref, notification);
                    },
                    onMarkAllRead:
                        notifications.any(
                          (notification) => notification.isUnread,
                        )
                        ? () {
                            ref
                                .read(notificationsControllerProvider.notifier)
                                .markAllAsRead();
                          }
                        : null,
                  ),
                  error: (error, _) => _NotificationsMessage(
                    icon: Icons.wifi_off_rounded,
                    title: 'Unable to load notifications',
                    message: error.toString(),
                  ),
                  loading: () => const _NotificationsLoadingView(),
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

class _NotificationsContent extends StatelessWidget {
  final List<InAppNotification> notifications;
  final ValueChanged<InAppNotification> onNotificationTap;
  final VoidCallback? onMarkAllRead;

  const _NotificationsContent({
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications
        .where((notification) => notification.isUnread)
        .length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 14.h),
            child: _NotificationsTitle(
              unreadCount: unreadCount,
              onMarkAllRead: onMarkAllRead,
            ),
          ),
        ),
        if (notifications.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _NotificationsMessage(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              message: 'New releases will appear here.',
            ),
          )
        else
          SliverList.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _NotificationCard(
                notification: notification,
                onTap: () => onNotificationTap(notification),
              );
            },
          ),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      ],
    );
  }
}

class _NotificationsTitle extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onMarkAllRead;

  const _NotificationsTitle({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final unreadLabel = unreadCount == 1 ? '1 unread' : '$unreadCount unread';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 26 : 21.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                unreadLabel,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? 15 : 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onMarkAllRead != null)
          TextButton(
            onPressed: onMarkAllRead,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: isTablet ? 15 : 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final InAppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final posterUrl = notification.posterUrl ?? '';
    final isUnread = notification.isUnread;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 14 : 10.w),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.card.withValues(alpha: 0.96)
              : AppColors.card.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.36)
                : AppColors.cardBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationLeading(
              type: notification.type,
              posterUrl: posterUrl,
              isTablet: isTablet,
            ),
            SizedBox(width: isTablet ? 14 : 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 17 : 14.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: isTablet ? 8 : 7.w,
                          height: isTablet ? 8 : 7.w,
                          margin: EdgeInsets.only(top: 5.h),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isTablet ? 14 : 12.sp,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.82),
                      fontSize: isTablet ? 13 : 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class _NotificationLeading extends StatelessWidget {
  final InAppNotificationType type;
  final String posterUrl;
  final bool isTablet;

  const _NotificationLeading({
    required this.type,
    required this.posterUrl,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final size = isTablet ? 72.0 : 58.w;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: posterUrl.isNotEmpty
          ? AppImage(source: posterUrl)
          : Container(
              color: AppColors.background.withValues(alpha: 0.72),
              child: Icon(
                _iconForType(type),
                color: AppColors.primary,
                size: isTablet ? 30 : 24.sp,
              ),
            ),
    );
  }

  IconData _iconForType(InAppNotificationType type) {
    return switch (type) {
      InAppNotificationType.newRelease => Icons.movie_creation_rounded,
      InAppNotificationType.purchaseSuccess => Icons.check_circle_rounded,
      InAppNotificationType.rentalExpiry => Icons.access_time_filled_rounded,
    };
  }
}

class _NotificationsLoadingView extends StatelessWidget {
  const _NotificationsLoadingView();

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

class _NotificationsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _NotificationsMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: isTablet ? 48 : 42.sp,
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 20 : 17.sp,
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
                fontSize: isTablet ? 15 : 12.sp,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
