import 'package:africanmovies/features/auth/auth_screen.dart';
import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/favorite/application/favorite_controller.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_hero.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_info_card.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_purchase_button.dart';
import 'package:africanmovies/features/movie_details/widgets/movie_small_action.dart';
import 'package:africanmovies/features/movie_list/movie_list_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/home_data.dart';
import 'package:africanmovies/features/movies/data/movie_repository.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/features/payment/application/payment_providers.dart';
import 'package:africanmovies/features/payment/domain/purchase_result.dart';
import 'package:africanmovies/features/payment/domain/saved_payment_method.dart';
import 'package:africanmovies/features/player/application/player_providers.dart';
import 'package:africanmovies/features/player/movie_player_screen.dart';
import 'package:africanmovies/features/player/trailer_player_screen.dart';
import 'package:africanmovies/features/watchlist/application/watchlist_controller.dart';
import 'package:africanmovies/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/section_movie_card.dart';

class MovieDetailsScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

enum _PurchasePaymentChoice { savedCard, newCard }

enum _SavePaymentMethodChoice { save, notNow, dontAskAgain }

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  bool _isTogglingWatchlist = false;
  bool _isTogglingFavorite = false;
  bool _isSavingPaymentMethod = false;
  bool _isOpeningPlayer = false;

  Movie get movie => widget.movie;

  bool _requireAuth(BuildContext context, WidgetRef ref) {
    final hasSession = ref.read(authControllerProvider).asData?.value != null;
    if (hasSession) return true;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return false;
  }

  void _openMovieList(BuildContext context, List<Movie> movies) {
    if (movies.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MovieListScreen(title: 'More Like This', movies: movies),
      ),
    );
  }

  Future<void> _toggleWatchlist() async {
    if (_isTogglingWatchlist) return;
    if (!_requireAuth(context, ref)) return;

    setState(() => _isTogglingWatchlist = true);

    try {
      final action = await ref
          .read(watchlistControllerProvider.notifier)
          .toggle(movie);

      if (!mounted) return;

      _showMessage(
        action == WatchlistAction.added
            ? 'Added to watchlist'
            : 'Removed from watchlist',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isTogglingWatchlist = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    if (!_requireAuth(context, ref)) return;

    setState(() => _isTogglingFavorite = true);

    try {
      final action = await ref
          .read(favoriteControllerProvider.notifier)
          .toggle(movie);

      if (!mounted) return;

      _showMessage(
        action == FavoriteAction.added
            ? 'Added to favorites'
            : 'Removed from favorites',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
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

  Future<void> _handleWatchNow(bool hasAccess) async {
    if (!_requireAuth(context, ref)) return;

    if (hasAccess) {
      await _openMoviePlayer();
      return;
    }

    await _startPurchaseFlow();
  }

  Future<void> _startPurchaseFlow() async {
    final savedPaymentMethod = await _readSavedPaymentMethod();
    if (!mounted) return;

    final purchaseChoice = await _showPurchaseConfirmation(savedPaymentMethod);
    if (purchaseChoice == null || !mounted) return;

    if (purchaseChoice == _PurchasePaymentChoice.savedCard) {
      await _purchaseWithSavedCard(savedPaymentMethod);
      return;
    }

    await _purchaseWithNewCard(existingSavedPaymentMethod: savedPaymentMethod);
  }

  Future<void> _openMoviePlayer() async {
    if (_isOpeningPlayer) return;

    setState(() => _isOpeningPlayer = true);

    var shouldOfferPurchase = false;

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
      shouldOfferPurchase =
          error is ApiException &&
          error.statusCode == 403 &&
          !movie.isFree &&
          !_isPurchaseInProgress;
    } finally {
      if (mounted) {
        setState(() => _isOpeningPlayer = false);
      }
    }

    if (shouldOfferPurchase && mounted) {
      await _startPurchaseFlow();
    }
  }

  bool get _isPurchaseInProgress {
    return ref.read(purchaseControllerProvider).isLoading;
  }

  Future<void> _purchaseWithNewCard({
    SavedPaymentMethod? existingSavedPaymentMethod,
  }) async {
    final result = await ref
        .read(purchaseControllerProvider.notifier)
        .purchaseMovie(context: context, movie: movie);

    if (!mounted) return;
    await _showPurchaseResult(
      result,
      existingSavedPaymentMethod: existingSavedPaymentMethod,
    );
  }

  Future<void> _purchaseWithSavedCard(
    SavedPaymentMethod? existingSavedPaymentMethod,
  ) async {
    final result = await ref
        .read(purchaseControllerProvider.notifier)
        .purchaseMovieWithSavedCard(context: context, movie: movie);

    if (!mounted) return;

    if (result.status == PurchaseResultStatus.failed) {
      final useAnotherCard = await _showUseAnotherCardPrompt(result.message);
      if (useAnotherCard == true && mounted) {
        await _purchaseWithNewCard(
          existingSavedPaymentMethod: existingSavedPaymentMethod,
        );
      }
      return;
    }

    await _showPurchaseResult(result);
  }

  Future<void> _showPurchaseResult(
    PurchaseResult result, {
    SavedPaymentMethod? existingSavedPaymentMethod,
  }) async {
    _showMessage(result.message);
    if (!result.canSavePaymentMethod) return;

    final existingPaymentMethod = existingSavedPaymentMethod;
    var hasExistingSavedCard = false;
    final bool? shouldSave;

    if (existingPaymentMethod != null && !existingPaymentMethod.isEmpty) {
      hasExistingSavedCard = true;
      shouldSave = await _showReplacePaymentMethodPrompt(existingPaymentMethod);
    } else {
      if (await _isSaveCardPromptHidden()) return;

      final saveChoice = await _showSavePaymentMethodPrompt();
      if (saveChoice == _SavePaymentMethodChoice.dontAskAgain) {
        await _hideSaveCardPrompt();
        return;
      }

      shouldSave = saveChoice == _SavePaymentMethodChoice.save;
    }

    if (shouldSave != true || !mounted) return;

    await _savePaymentMethod(
      result.transactionId!,
      successMessage: hasExistingSavedCard
          ? 'Saved card replaced for future purchases.'
          : 'Card saved for faster checkout.',
    );
  }

  Future<void> _savePaymentMethod(
    String transactionId, {
    required String successMessage,
  }) async {
    if (_isSavingPaymentMethod) return;

    setState(() => _isSavingPaymentMethod = true);

    try {
      await ref
          .read(savedPaymentMethodControllerProvider.notifier)
          .saveFromTransaction(transactionId);

      if (!mounted) return;
      _showMessage(successMessage);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSavingPaymentMethod = false);
      }
    }
  }

  Future<bool> _isSaveCardPromptHidden() async {
    try {
      return await ref
          .read(paymentPreferencesStoreProvider)
          .isSaveCardPromptHidden();
    } catch (_) {
      return false;
    }
  }

  Future<void> _hideSaveCardPrompt() async {
    try {
      await ref.read(paymentPreferencesStoreProvider).hideSaveCardPrompt();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update card prompt preference.');
    }
  }

  Future<bool?> _showUseAnotherCardPrompt(String message) {
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
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warning.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.36),
                            ),
                          ),
                          child: Icon(
                            Icons.credit_card_off_rounded,
                            color: AppColors.warning,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Saved card could not be used',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 13.h),
                    Text(
                      message,
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
                            backgroundColor: Colors.transparent,
                            borderColor: AppColors.cardBorder,
                            textColor: AppColors.textSecondary,
                            onPressed: () => Navigator.pop(sheetContext, false),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: AppButton(
                            text: 'Use Another Card',
                            height: 46.h,
                            fontSize: 13.sp,
                            borderRadius: AppRadius.sm,
                            backgroundColor: AppColors.heroButton,
                            borderColor: AppColors.heroButton,
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

  Future<SavedPaymentMethod?> _readSavedPaymentMethod() async {
    try {
      final paymentMethod = await ref.read(
        savedPaymentMethodControllerProvider.future,
      );
      if (paymentMethod == null || paymentMethod.isEmpty) return null;

      return paymentMethod;
    } catch (_) {
      return null;
    }
  }

  Future<_PurchasePaymentChoice?> _showPurchaseConfirmation(
    SavedPaymentMethod? savedPaymentMethod,
  ) {
    return showModalBottomSheet<_PurchasePaymentChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final hasSavedCard = savedPaymentMethod != null;

        return Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, bottomInset + 14.h),
          child: Container(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.heroButton.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.heroButton.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_open_rounded,
                        color: AppColors.heroButton,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase movie',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        movie.priceLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                if (hasSavedCard) ...[
                  _SavedCardPurchaseOption(paymentMethod: savedPaymentMethod),
                  SizedBox(height: 12.h),
                ],
                Text(
                  hasSavedCard
                      ? 'Choose how you want to complete this purchase.'
                      : 'After checkout, we will verify the payment before adding this movie to your library.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 18.h),
                if (hasSavedCard) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Use Another Card',
                          height: 44.h,
                          fontSize: 13.sp,
                          borderRadius: AppRadius.sm,
                          backgroundColor: Colors.transparent,
                          borderColor: AppColors.cardBorder,
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            _PurchasePaymentChoice.newCard,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: AppButton(
                          text: 'Use Saved Card',
                          height: 44.h,
                          fontSize: 13.sp,
                          borderRadius: AppRadius.sm,
                          backgroundColor: AppColors.heroButton,
                          borderColor: AppColors.heroButton,
                          icon: Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 17.sp,
                          ),
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            _PurchasePaymentChoice.savedCard,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Cancel',
                          height: 44.h,
                          fontSize: 13.sp,
                          borderRadius: AppRadius.sm,
                          backgroundColor: Colors.transparent,
                          borderColor: AppColors.cardBorder,
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: AppButton(
                          text: 'Confirm',
                          height: 44.h,
                          fontSize: 13.sp,
                          borderRadius: AppRadius.sm,
                          backgroundColor: AppColors.heroButton,
                          borderColor: AppColors.heroButton,
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            _PurchasePaymentChoice.newCard,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_SavePaymentMethodChoice?> _showSavePaymentMethodPrompt() {
    var hideFuturePrompts = false;

    return showModalBottomSheet<_SavePaymentMethodChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final screenHeight = MediaQuery.sizeOf(sheetContext).height;
        final maxWidth = Responsive.isTablet(sheetContext)
            ? 470.0
            : double.infinity;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    14.w,
                    0,
                    14.w,
                    bottomInset + 14.h,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 16.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0B1424),
                              Color(0xFF09111F),
                              Color(0xFF050A13),
                            ],
                          ),
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
                            Center(
                              child: Container(
                                width: 42.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46.w,
                                  height: 46.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    color: AppColors.heroButton.withValues(
                                      alpha: 0.13,
                                    ),
                                    border: Border.all(
                                      color: AppColors.heroButton.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: AppColors.primary,
                                    size: 22.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Save card for next time?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF22C55E,
                                              ).withValues(alpha: 0.13),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.full,
                                                  ),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF22C55E,
                                                ).withValues(alpha: 0.32),
                                              ),
                                            ),
                                            child: Text(
                                              'OPTIONAL',
                                              style: TextStyle(
                                                color: const Color(0xFF86EFAC),
                                                fontSize: 8.5.sp,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5.h),
                                      Text(
                                        'Pay faster on your next movie purchase.',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            const _SavePaymentCardPreview(),
                            SizedBox(height: 16.h),
                            Text(
                              'We save a secure payment token with Flutterwave. Your full card number and CVV are never stored in AfricanMovies.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            const _SavePaymentBenefits(),
                            SizedBox(height: 12.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: const Color(0xFFFBBF24),
                                    size: 17.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Some cards may still ask for bank verification when needed.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.sp,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(
                                  color: hideFuturePrompts
                                      ? AppColors.heroButton.withValues(
                                          alpha: 0.34,
                                        )
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_off_outlined,
                                          color: hideFuturePrompts
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            "Don't ask again on this device",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: hideFuturePrompts
                                                  ? Colors.white.withValues(
                                                      alpha: 0.9,
                                                    )
                                                  : AppColors.textSecondary,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.82,
                                    child: Switch.adaptive(
                                      value: hideFuturePrompts,
                                      activeThumbColor: AppColors.heroButton,
                                      activeTrackColor: AppColors.heroButton
                                          .withValues(alpha: 0.32),
                                      inactiveThumbColor:
                                          AppColors.textSecondary,
                                      inactiveTrackColor: Colors.white
                                          .withValues(alpha: 0.12),
                                      onChanged: (value) {
                                        setSheetState(
                                          () => hideFuturePrompts = value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    text: 'Not Now',
                                    height: 46.h,
                                    fontSize: 13.sp,
                                    borderRadius: AppRadius.sm,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.03,
                                    ),
                                    borderColor: AppColors.cardBorder,
                                    textColor: AppColors.textSecondary,
                                    onPressed: () => Navigator.pop(
                                      sheetContext,
                                      hideFuturePrompts
                                          ? _SavePaymentMethodChoice
                                                .dontAskAgain
                                          : _SavePaymentMethodChoice.notNow,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: AppButton(
                                    text: 'Save Card',
                                    height: 46.h,
                                    fontSize: 13.sp,
                                    borderRadius: AppRadius.sm,
                                    backgroundColor: AppColors.heroButton,
                                    borderColor: AppColors.heroButton,
                                    icon: Icon(
                                      Icons.verified_user_rounded,
                                      color: Colors.white,
                                      size: 17.sp,
                                    ),
                                    onPressed: () => Navigator.pop(
                                      sheetContext,
                                      _SavePaymentMethodChoice.save,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Center(
                              child: Text(
                                'You can remove it later in Payment Details.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _showReplacePaymentMethodPrompt(
    SavedPaymentMethod currentPaymentMethod,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
        final screenHeight = MediaQuery.sizeOf(sheetContext).height;
        final maxWidth = Responsive.isTablet(sheetContext)
            ? 470.0
            : double.infinity;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, bottomInset + 14.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 16.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0A1A2F),
                          Color(0xFF07111F),
                          Color(0xFF030812),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: AppColors.heroButton.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.heroButton.withValues(alpha: 0.16),
                          blurRadius: 34.r,
                          offset: Offset(0, 14.h),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.42),
                          blurRadius: 36.r,
                          offset: Offset(0, 22.h),
                        ),
                      ],
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF22C55E,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.32),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF86EFAC),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  'PURCHASE COMPLETE',
                                  style: TextStyle(
                                    color: const Color(0xFF86EFAC),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Replace saved card?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(height: 7.h),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Keep your current card, or save the card you just used for faster checkout next time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 18.h),
                        _ReplacePaymentMethodPreview(
                          paymentMethod: currentPaymentMethod,
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: const Color(
                                0xFF22C55E,
                              ).withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: const Color(0xFF86EFAC),
                                size: 17.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Nothing changes unless you approve it. Your movie access is already secured.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 11.sp,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Keep Current',
                                height: 46.h,
                                fontSize: 13.sp,
                                borderRadius: AppRadius.sm,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.06,
                                ),
                                borderColor: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                                textColor: Colors.white.withValues(alpha: 0.78),
                                icon: Icon(
                                  Icons.credit_score_rounded,
                                  color: Colors.white.withValues(alpha: 0.72),
                                  size: 17.sp,
                                ),
                                onPressed: () =>
                                    Navigator.pop(sheetContext, false),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: AppButton(
                                text: 'Replace Card',
                                height: 46.h,
                                fontSize: 13.sp,
                                borderRadius: AppRadius.sm,
                                backgroundColor: AppColors.heroButton,
                                borderColor: AppColors.heroButton,
                                icon: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 17.sp,
                                ),
                                onPressed: () =>
                                    Navigator.pop(sheetContext, true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openTrailer(BuildContext context) {
    final trailerUrl = movie.trailerUrl.trim();

    if (trailerUrl.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Trailer unavailable')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrailerPlayerScreen(title: movie.title, videoUrl: trailerUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final homeDataState = ref.watch(homeDataProvider);
    final relatedMovies = _relatedMovies(homeDataState);
    final hasSession = ref.watch(authControllerProvider).asData?.value != null;
    final hasAccess = _hasMovieAccess(homeDataState);
    final purchaseState = ref.watch(purchaseControllerProvider);
    final isPurchasing =
        purchaseState.isLoading || _isSavingPaymentMethod || _isOpeningPlayer;
    final watchlistState = hasSession
        ? ref.watch(watchlistControllerProvider)
        : const AsyncData<List<Movie>>([]);
    final favoriteState = hasSession
        ? ref.watch(favoriteControllerProvider)
        : const AsyncData<List<Movie>>([]);
    final isInWatchlist = hasSession && _isMovieInWatchlist(watchlistState);
    final isFavorite = hasSession && _isMovieFavorite(favoriteState);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MovieHero(movie: movie),
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
                              icon: hasAccess
                                  ? Icons.play_arrow_rounded
                                  : Icons.lock_outline_rounded,
                              title: hasAccess
                                  ? 'Watch Now'
                                  : 'Watch for ${movie.priceLabel}',
                              subtitle: hasAccess
                                  ? movie.isFree
                                        ? 'Free title'
                                        : 'In your library'
                                  : 'Add to your library',
                              isLoading: isPurchasing,
                              onTap: isPurchasing
                                  ? null
                                  : () => _handleWatchNow(hasAccess),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: Icons.smart_display_outlined,
                            label: 'Trailer',
                            onTap: () => _openTrailer(context),
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: isInWatchlist
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            label: isInWatchlist ? 'Saved' : 'Watchlist',
                            isActive: isInWatchlist,
                            isLoading: _isTogglingWatchlist,
                            onTap: _toggleWatchlist,
                          ),
                          SizedBox(width: 6.w),
                          MovieSmallAction(
                            icon: isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: isFavorite ? 'Liked' : 'Favorite',
                            isActive: isFavorite,
                            isLoading: _isTogglingFavorite,
                            onTap: _toggleFavorite,
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      _MovieDescription(description: movie.description),

                      SizedBox(height: 12.h),

                      MovieInfoCard(movie: movie),

                      if (relatedMovies.isNotEmpty) ...[
                        SizedBox(height: 14.h),

                        SectionHeader(
                          title: 'More Like This',
                          actionText: 'See All »',
                          onActionTap: () {
                            _openMovieList(context, relatedMovies);
                          },
                        ),

                        SizedBox(height: 12.h),

                        SizedBox(
                          height: 168.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedMovies.length,
                            separatorBuilder: (_, _) => SizedBox(width: 8.w),
                            itemBuilder: (_, index) {
                              final relatedMovie = relatedMovies[index];

                              return SectionMovieCard(
                                image: relatedMovie.displayPosterUrl,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailsScreen(
                                        movie: relatedMovie,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
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

  bool _isMovieInWatchlist(AsyncValue<List<Movie>> watchlistState) {
    return watchlistState.when(
      data: (movies) => movies.any((movie) => movie.id == widget.movie.id),
      loading: () => widget.movie.inWatchlist,
      error: (_, _) => widget.movie.inWatchlist,
    );
  }

  bool _isMovieFavorite(AsyncValue<List<Movie>> favoriteState) {
    return favoriteState.when(
      data: (movies) => movies.any((movie) => movie.id == widget.movie.id),
      loading: () => widget.movie.isFavorite,
      error: (_, _) => widget.movie.isFavorite,
    );
  }

  bool _hasMovieAccess(AsyncValue<HomeData> homeDataState) {
    if (movie.isFree) return true;

    return homeDataState.maybeWhen(
      data: (data) {
        return data.orders.any(
          (order) => order.paid && order.movieId == movie.id,
        );
      },
      orElse: () => false,
    );
  }

  List<Movie> _relatedMovies(AsyncValue<HomeData> homeDataState) {
    final selectedGenre = movie.genre.trim().toLowerCase();
    if (selectedGenre.isEmpty) return const [];

    return homeDataState.maybeWhen(
      data: (data) => data.movies
          .where(
            (relatedMovie) =>
                relatedMovie.id != movie.id &&
                relatedMovie.genre.trim().toLowerCase() == selectedGenre,
          )
          .take(12)
          .toList(),
      orElse: () => const <Movie>[],
    );
  }
}

class _SavedCardPurchaseOption extends StatelessWidget {
  final SavedPaymentMethod paymentMethod;

  const _SavedCardPurchaseOption({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.heroButton.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.heroButton.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: AppColors.background.withValues(alpha: 0.45),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(
              Icons.credit_card_rounded,
              color: AppColors.heroButton,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentMethod.displayCardType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  paymentMethod.maskedNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 24.w,
            height: 24.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.heroButton,
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: 16.sp),
          ),
        ],
      ),
    );
  }
}

class _ReplacePaymentMethodPreview extends StatelessWidget {
  final SavedPaymentMethod paymentMethod;

  const _ReplacePaymentMethodPreview({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.72;

        return SizedBox(
          height: 172.h,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: cardWidth,
                child: _PaymentSwapCard(
                  eyebrow: 'CURRENT SAVED',
                  title: paymentMethod.displayCardType,
                  subtitle: paymentMethod.maskedNumber,
                  icon: Icons.credit_card_rounded,
                  accentColor: AppColors.textSecondary,
                  gradient: const [
                    Color(0xFF101B2B),
                    Color(0xFF0A1220),
                    Color(0xFF050A13),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                width: cardWidth,
                child: _PaymentSwapCard(
                  eyebrow: 'CARD JUST USED',
                  title: 'New checkout card',
                  subtitle: 'Available after you approve',
                  icon: Icons.verified_user_rounded,
                  accentColor: const Color(0xFF86EFAC),
                  gradient: const [
                    Color(0xFF006FE6),
                    Color(0xFF073B73),
                    Color(0xFF06111F),
                  ],
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                      border: Border.all(
                        color: AppColors.heroButton.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.heroButton.withValues(alpha: 0.22),
                          blurRadius: 18.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentSwapCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradient;

  const _PaymentSwapCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108.h,
      padding: EdgeInsets.fromLTRB(13.w, 12.h, 13.w, 11.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 18.r,
            offset: Offset(0, 9.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.contactless_rounded,
              color: Colors.white.withValues(alpha: 0.36),
              size: 21.sp,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.95),
                          accentColor.withValues(alpha: 0.34),
                        ],
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 13.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.66),
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavePaymentCardPreview extends StatelessWidget {
  const _SavePaymentCardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 138.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B64C9), Color(0xFF08213F), Color(0xFF050A13)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroButton.withValues(alpha: 0.22),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2.h,
            right: 0,
            child: Icon(
              Icons.contactless_rounded,
              color: Colors.white.withValues(alpha: 0.54),
              size: 24.sp,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD166), Color(0xFFB7791F)],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'SECURE TOKEN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'AfricanMovies Checkout',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '••••  ••••  ••••  CARD',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 7.h),
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: const Color(0xFF86EFAC),
                    size: 15.sp,
                  ),
                  SizedBox(width: 5.w),
                  Flexible(
                    child: Text(
                      'Full number and CVV stay private',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavePaymentBenefits extends StatelessWidget {
  const _SavePaymentBenefits();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: const [
        _SavePaymentBenefitPill(
          icon: Icons.flash_on_rounded,
          label: 'Faster checkout',
        ),
        _SavePaymentBenefitPill(
          icon: Icons.verified_user_outlined,
          label: 'Protected',
        ),
        _SavePaymentBenefitPill(
          icon: Icons.lock_outline_rounded,
          label: 'No CVV stored',
        ),
      ],
    );
  }
}

class _SavePaymentBenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SavePaymentBenefitPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 15.sp),
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

class _MovieDescription extends StatefulWidget {
  final String description;

  const _MovieDescription({required this.description});

  @override
  State<_MovieDescription> createState() => _MovieDescriptionState();
}

class _MovieDescriptionState extends State<_MovieDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.description.trim();
    if (description.isEmpty) return const SizedBox.shrink();

    final canExpand = description.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
        if (canExpand) ...[
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded ? 'Read Less' : 'Read More',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heroButton,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.heroButton,
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
