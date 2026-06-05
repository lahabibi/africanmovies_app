import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_screen_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _supportEmail = 'info@africanmovies.com';

  static const _supportTopics = [
    _SupportTopic(
      icon: Icons.play_circle_outline_rounded,
      title: 'Getting Started',
      subtitle: 'Signing in and watching your first movie',
      answer:
          'Use your email to request an OTP, then enter the code sent to your inbox. Once signed in, you can browse movies, open details, watch trailers, and purchase titles when payment is enabled.',
    ),
    _SupportTopic(
      icon: Icons.credit_card_rounded,
      title: 'Payment & Billing',
      subtitle: 'Purchases, payment failures, and access',
      answer:
          'Movies are purchased per title. If a payment fails, check your connection, confirm your payment details, and try again. If you were charged but access did not update, contact support with your account email and movie title.',
    ),
    _SupportTopic(
      icon: Icons.smart_display_outlined,
      title: 'Watching & Playback',
      subtitle: 'Trailer, audio, and video playback issues',
      answer:
          'For playback issues, confirm your internet is stable, close and reopen the player, then try again. If sound works on other apps but not AfricanMovies, include your device model and the movie or trailer title when contacting support.',
    ),
    _SupportTopic(
      icon: Icons.phone_iphone_rounded,
      title: 'Logged In Devices',
      subtitle: 'Managing active sessions and device limits',
      answer:
          'AfricanMovies limits how many devices can stay signed in at once. You can review active devices from Profile > Logged In Devices and sign out devices you no longer use.',
    ),
    _SupportTopic(
      icon: Icons.person_outline_rounded,
      title: 'Account & Profile',
      subtitle: 'Profile picture, username, and account email',
      answer:
          'You can update your username and profile picture from Edit Profile. Your email is used for OTP sign-in and support checks, so include it when asking for help.',
    ),
    _SupportTopic(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet',
      subtitle: 'What happens when connection is unavailable',
      answer:
          'If your internet drops, protected online features are paused until the connection returns. Once you are back online, the app refreshes automatically so you can continue.',
    ),
  ];

  Future<void> _openSupportEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'AfricanMovies Support Request',
        'body':
            'Hello AfricanMovies Support,\n\n'
            'Account email:\n'
            'Movie title, if any:\n'
            'Issue:\n\n',
      },
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!context.mounted) return;

      if (!launched) {
        await _copySupportEmail(
          context,
          message: 'No mail app found. Support email copied.',
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      await _copySupportEmail(
        context,
        message: 'No mail app found. Support email copied.',
      );
    }
  }

  Future<void> _copySupportEmail(
    BuildContext context, {
    String message = 'Support email copied',
  }) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
                        'Help & Support',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Find quick answers or contact the AfricanMovies support team.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 22.h),

                      _ContactSupportCard(
                        email: _supportEmail,
                        onContact: () => _openSupportEmail(context),
                        onCopyEmail: () => _copySupportEmail(context),
                      ),

                      SizedBox(height: 22.h),

                      Text(
                        'Quick Answers',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: List.generate(_supportTopics.length, (
                            index,
                          ) {
                            final topic = _supportTopics[index];

                            return _HelpTopicTile(
                              topic: topic,
                              showDivider: index != _supportTopics.length - 1,
                            );
                          }),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      _SupportTipCard(
                        onContact: () => _openSupportEmail(context),
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

class _ContactSupportCard extends StatelessWidget {
  final String email;
  final VoidCallback onContact;
  final VoidCallback onCopyEmail;

  const _ContactSupportCard({
    required this.email,
    required this.onContact,
    required this.onCopyEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          final details = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.heroButton.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppColors.heroButton.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  Icons.headset_mic_outlined,
                  color: AppColors.heroButton,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Send us your account email, device model, and a short description of the issue.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _SupportEmailPill(email: email, onTap: onCopyEmail),
                  ],
                ),
              ),
            ],
          );

          final button = AppButton(
            text: 'Email Support',
            icon: Icon(Icons.email_outlined, color: Colors.white, size: 18.sp),
            height: 46.h,
            width: isWide ? 172.w : double.infinity,
            fontSize: 14.sp,
            borderRadius: AppRadius.sm,
            backgroundColor: AppColors.heroButton,
            borderColor: AppColors.heroButton,
            textColor: Colors.white,
            onPressed: onContact,
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: details),
                SizedBox(width: 18.w),
                button,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              SizedBox(height: 16.h),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _SupportEmailPill extends StatelessWidget {
  final String email;
  final VoidCallback onTap;

  const _SupportEmailPill({required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heroButton,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.copy_rounded,
                color: AppColors.heroButton,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpTopicTile extends StatelessWidget {
  final _SupportTopic topic;
  final bool showDivider;

  const _HelpTopicTile({required this.topic, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            childrenPadding: EdgeInsets.fromLTRB(64.w, 0, 18.w, 16.h),
            iconColor: AppColors.heroButton,
            collapsedIconColor: AppColors.textSecondary,
            leading: Icon(topic.icon, color: AppColors.heroButton, size: 28.sp),
            title: Text(
              topic.title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                topic.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  topic.answer,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 64.w, right: 18.w),
            child: Divider(height: 1, color: AppColors.cardBorder),
          ),
      ],
    );
  }
}

class _SupportTipCard extends StatelessWidget {
  final VoidCallback onContact;

  const _SupportTipCard({required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onContact,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.heroButton.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.heroButton.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.heroButton,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'For faster support, include screenshots and the exact movie title when possible.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.heroButton,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTopic {
  final IconData icon;
  final String title;
  final String subtitle;
  final String answer;

  const _SupportTopic({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.answer,
  });
}
