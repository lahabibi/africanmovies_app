import 'package:africanmovies/features/profile/widgets/payment_card_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/responsive.dart';
import '../../features/payment/application/payment_providers.dart';
import '../../features/payment/domain/saved_payment_method.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/app_screen_header.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/empty_state.dart';

class PaymentDetailsScreen extends ConsumerWidget {
  const PaymentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = Responsive.headerHeight(context);
    final paymentMethodState = ref.watch(savedPaymentMethodControllerProvider);
    final saveCardPromptPreferenceState = ref.watch(
      saveCardPromptPreferenceControllerProvider,
    );

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
                    maxWidth: Responsive.formMaxWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),
                      Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        'Manage your saved payment method for movie purchases.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 22.h),

                      _SaveCardPromptPreferenceCard(
                        state: saveCardPromptPreferenceState,
                        onChanged: (shouldAsk) async {
                          try {
                            await ref
                                .read(
                                  saveCardPromptPreferenceControllerProvider
                                      .notifier,
                                )
                                .setShouldAskAfterCheckout(shouldAsk);

                            if (!context.mounted) return;
                            _showMessage(
                              context,
                              shouldAsk
                                  ? 'Save-card prompt enabled.'
                                  : 'Save-card prompt disabled.',
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            _showMessage(context, _messageFor(error));
                          }
                        },
                      ),

                      SizedBox(height: 22.h),

                      paymentMethodState.when(
                        data: (paymentMethod) {
                          if (paymentMethod == null || paymentMethod.isEmpty) {
                            return const EmptyState(
                              title: 'No saved payment method',
                              subtitle:
                                  'Save a card after checkout and it will appear here.',
                              icon: Icons.credit_card_off_rounded,
                            );
                          }

                          return _SavedPaymentMethodView(
                            paymentMethod: paymentMethod,
                            onRemoveCard: () =>
                                _confirmAndRemoveCard(context, ref),
                          );
                        },
                        loading: () => const _PaymentDetailsLoading(),
                        error: (_, _) => _PaymentDetailsError(
                          onRetry: () => ref.invalidate(
                            savedPaymentMethodControllerProvider,
                          ),
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

  Future<void> _confirmAndRemoveCard(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldRemove = await _showRemoveCardConfirmation(context);
    if (shouldRemove != true || !context.mounted) return;

    try {
      await ref
          .read(savedPaymentMethodControllerProvider.notifier)
          .removeSavedPaymentMethod();

      if (!context.mounted) return;
      _showMessage(context, 'Saved card removed.');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, _messageFor(error));
    }
  }

  Future<bool?> _showRemoveCardConfirmation(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final maxWidth = Responsive.isTablet(sheetContext)
            ? 470.0
            : double.infinity;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, bottomInset + 14.h),
              child: Container(
                padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 30.r,
                      offset: Offset(0, 18.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46.w,
                          height: 46.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.danger.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 23.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Remove saved card?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'This removes the saved payment token from your account. Your purchased movies will stay in your library, but future purchases will ask for card details again.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cancel',
                            height: 46.h,
                            fontSize: 13.sp,
                            borderRadius: AppRadius.sm,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.03,
                            ),
                            borderColor: AppColors.cardBorder,
                            textColor: AppColors.textSecondary,
                            onPressed: () => Navigator.pop(sheetContext, false),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: AppButton(
                            text: 'Remove',
                            height: 46.h,
                            fontSize: 13.sp,
                            borderRadius: AppRadius.sm,
                            backgroundColor: AppColors.danger,
                            borderColor: AppColors.danger,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 17.sp,
                            ),
                            onPressed: () => Navigator.pop(sheetContext, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;

    return error.toString();
  }
}

class _SavedPaymentMethodView extends StatelessWidget {
  final SavedPaymentMethod paymentMethod;
  final VoidCallback onRemoveCard;

  const _SavedPaymentMethodView({
    required this.paymentMethod,
    required this.onRemoveCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Card',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),

        SizedBox(height: 14.h),

        _PhysicalPaymentCard(paymentMethod: paymentMethod),

        SizedBox(height: 18.h),

        Row(
          children: [
            Expanded(
              child: _PaymentInfoTile(
                icon: Icons.public_rounded,
                label: 'Country',
                value: paymentMethod.displayCountry,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _PaymentInfoTile(
                icon: paymentMethod.needsRefresh
                    ? Icons.warning_amber_rounded
                    : Icons.event_available_rounded,
                label: 'Token refresh',
                value: paymentMethod.needsRefresh ? 'Due' : 'Active',
                isWarning: paymentMethod.needsRefresh,
              ),
            ),
          ],
        ),

        SizedBox(height: 18.h),

        const _SecurePaymentNotice(),

        SizedBox(height: 18.h),

        _RemoveCardButton(onTap: onRemoveCard),
      ],
    );
  }
}

class _SaveCardPromptPreferenceCard extends StatelessWidget {
  final AsyncValue<bool> state;
  final Future<void> Function(bool shouldAsk) onChanged;

  const _SaveCardPromptPreferenceCard({
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final shouldAsk = state.asData?.value ?? true;
    final isLoading = state.isLoading;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 10.w, 13.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: shouldAsk
              ? AppColors.heroButton.withValues(alpha: 0.28)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroButton.withValues(
              alpha: shouldAsk ? 0.08 : 0.03,
            ),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: AppColors.heroButton.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.heroButton.withValues(alpha: 0.30),
              ),
            ),
            child: Icon(
              shouldAsk
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              color: shouldAsk ? AppColors.primary : AppColors.textSecondary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask to save card after checkout',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  shouldAsk
                      ? 'We can ask after successful card purchases.'
                      : 'Save-card prompts are hidden on this device.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (isLoading)
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.2.w,
                color: AppColors.heroButton,
              ),
            )
          else
            Transform.scale(
              scale: 0.86,
              child: Switch.adaptive(
                value: shouldAsk,
                activeThumbColor: AppColors.heroButton,
                activeTrackColor: AppColors.heroButton.withValues(alpha: 0.32),
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class _PhysicalPaymentCard extends StatelessWidget {
  final SavedPaymentMethod paymentMethod;

  const _PhysicalPaymentCard({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1473B8), Color(0xFF0A2F56), Color(0xFF07101D)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroButton.withValues(alpha: 0.25),
            blurRadius: 28.r,
            offset: Offset(0, 14.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          children: [
            Positioned(
              right: -44.w,
              top: -44.w,
              child: Container(
                width: 150.w,
                height: 150.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -28.w,
              right: -28.w,
              top: 64.h,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  height: 42.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.075),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -12.w,
              right: -12.w,
              bottom: 22.h,
              child: Transform.rotate(
                angle: 0.16,
                child: Container(
                  height: 1.2.h,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(22.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PhysicalCardChip(),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AfricanMovies',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              paymentMethod.displayCardType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      const _ContactlessMark(),
                    ],
                  ),
                  SizedBox(height: 34.h),
                  Text(
                    'Card Number',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            paymentMethod.maskedNumber,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      _CardStatusBadge(
                        text: paymentMethod.isNewPay ? 'NEW' : 'SAVED',
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: PaymentCardInfo(
                          label: 'PAYMENT EMAIL',
                          value: paymentMethod.displayEmail,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      PaymentCardInfo(
                        label: 'EXPIRES',
                        value: paymentMethod.displayExpiry,
                        alignEnd: true,
                      ),
                    ],
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

class _PhysicalCardChip extends StatelessWidget {
  const _PhysicalCardChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.w,
      height: 31.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE19A), Color(0xFFC98F32), Color(0xFF7C551B)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 9.h,
            child: Container(
              height: 1.h,
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 9.h,
            child: Container(
              height: 1.h,
              color: Colors.black.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 14.w,
            child: Container(
              width: 1.w,
              color: Colors.black.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 14.w,
            child: Container(
              width: 1.w,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactlessMark extends StatelessWidget {
  const _ContactlessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(
        Icons.contactless_rounded,
        color: Colors.white.withValues(alpha: 0.74),
        size: 22.sp,
      ),
    );
  }
}

class _CardStatusBadge extends StatelessWidget {
  final String text;

  const _CardStatusBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.heroButton.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.heroButton.withValues(alpha: 0.7)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PaymentInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _PaymentInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isWarning ? AppColors.warning : AppColors.heroButton;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurePaymentNotice extends StatelessWidget {
  const _SecurePaymentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.heroButton.withValues(alpha: 0.14),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 22.sp,
              color: AppColors.heroButton,
            ),
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payments',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Your card token is securely stored for future purchases. AfricanMovies never stores your CVV.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveCardButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Remove Card',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentDetailsLoading extends StatelessWidget {
  const _PaymentDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 42.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.heroButton),
      ),
    );
  }
}

class _PaymentDetailsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _PaymentDetailsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 32.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'Could not load payment details',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              height: 42.h,
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              decoration: BoxDecoration(
                color: AppColors.heroButton,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
