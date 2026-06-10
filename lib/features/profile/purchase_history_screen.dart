import 'package:africanmovies/features/payment/application/payment_providers.dart';
import 'package:africanmovies/features/payment/domain/payment_history.dart';
import 'package:africanmovies/shared/widgets/app_image.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';

class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(paymentHistoryProvider);
    await ref.read(paymentHistoryProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = Responsive.headerHeight(context);
    final historyState = ref.watch(paymentHistoryProvider);

    return AppScaffold(
      usePadding: true,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: headerHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.formMaxWidth(context),
                ),
                child: historyState.when(
                  data: (history) => _PurchaseHistoryContent(
                    history: history,
                    onRefresh: () => _refresh(ref),
                  ),
                  loading: _PurchaseHistoryLoading.new,
                  error: (error, _) => _PurchaseHistoryError(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(paymentHistoryProvider),
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

class _PurchaseHistoryContent extends StatelessWidget {
  final PaymentHistoryResponse history;
  final Future<void> Function() onRefresh;

  const _PurchaseHistoryContent({
    required this.history,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            Text(
              'Purchase History',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Orders, payments, and access status.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 14.h),
            _HistorySummary(summary: history.summary),
            SizedBox(height: 14.h),
            if (history.items.isEmpty)
              const _PurchaseHistoryEmpty()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.items.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final item = history.items[index];

                  return _PurchaseHistoryCard(
                    item: item,
                    onTap: () => _showPurchaseHistoryDetails(context, item),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  final PaymentHistorySummary summary;

  const _HistorySummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _SummaryChip(
          icon: Icons.receipt_long_rounded,
          label: '${summary.total} Total',
        ),
        _SummaryChip(
          icon: Icons.check_circle_outline_rounded,
          label: '${summary.completed} Completed',
          color: const Color(0xFF22C55E),
        ),
        _SummaryChip(
          icon: Icons.play_circle_outline_rounded,
          label: '${summary.active} Active',
          color: AppColors.heroButton,
        ),
        if (summary.expired > 0)
          _SummaryChip(
            icon: Icons.history_rounded,
            label: '${summary.expired} Expired',
            color: AppColors.warning,
          ),
        if (summary.failed > 0)
          _SummaryChip(
            icon: Icons.error_outline_rounded,
            label: '${summary.failed} Failed',
            color: AppColors.danger,
          ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
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
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseHistoryCard extends StatelessWidget {
  final PaymentHistoryItem item;
  final VoidCallback onTap;

  const _PurchaseHistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 108.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 78.w,
              height: double.infinity,
              child: AppImage(source: item.posterUrl),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(11.w, 10.h, 10.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          item.displayAmount,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${item.paymentStatusLabel} / ${item.displayDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _StatusPill(
                          label: item.accessStatusLabel,
                          color: item.accessStatusColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'TX ${item.txRefLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                          size: 21.sp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PurchaseHistoryEmpty extends StatelessWidget {
  const _PurchaseHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.heroButton,
            size: 38.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'No purchases yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            'Your completed payments and claimed movies will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseHistoryLoading extends StatelessWidget {
  const _PurchaseHistoryLoading();

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

class _PurchaseHistoryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PurchaseHistoryError({required this.message, required this.onRetry});

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
              'Unable to load purchase history',
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

Future<void> _showPurchaseHistoryDetails(
  BuildContext context,
  PaymentHistoryItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _PurchaseHistoryDetailsSheet(item: item);
    },
  );
}

class _PurchaseHistoryDetailsSheet extends StatelessWidget {
  final PaymentHistoryItem item;

  const _PurchaseHistoryDetailsSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(10.w),
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 58.w,
                    height: 76.h,
                    child: AppImage(source: item.posterUrl),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 7.h),
                      _StatusPill(
                        label: item.accessStatusLabel,
                        color: item.accessStatusColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            _DetailRow(label: 'Amount', value: item.displayAmount),
            _DetailRow(label: 'Payment Status', value: item.paymentStatusLabel),
            _DetailRow(label: 'Access Status', value: item.accessStatusLabel),
            _DetailRow(label: 'Date', value: item.displayDate),
            _DetailRow(
              label: 'TX Ref',
              value: item.txRef.isEmpty ? 'N/A' : item.txRef,
            ),
            _DetailRow(
              label: 'Transaction ID',
              value: item.payment?.transactionId?.trim().isNotEmpty == true
                  ? item.payment!.transactionId!
                  : 'N/A',
            ),
            _DetailRow(
              label: 'Order ID',
              value: item.order?.id.trim().isNotEmpty == true
                  ? item.order!.id
                  : 'N/A',
            ),
            _DetailRow(
              label: 'Expires',
              value: item.order?.expiryDate == null
                  ? 'N/A'
                  : _formatDate(item.order!.expiryDate),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104.w,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'N/A';

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

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
