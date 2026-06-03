import 'dart:async';

import 'package:africanmovies/features/movie_details/movie_details_screen.dart';
import 'package:africanmovies/features/movies/application/movie_providers.dart';
import 'package:africanmovies/features/movies/domain/movie.dart';
import 'package:africanmovies/shared/widgets/app_image.dart';
import 'package:africanmovies/shared/widgets/app_scaffold.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _debounceDuration = Duration(milliseconds: 350);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _inputQuery = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _inputQuery = value);

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    setState(() => _searchQuery = value.trim());
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _inputQuery = '';
      _searchQuery = '';
    });
    _focusNode.requestFocus();
  }

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = Responsive.headerHeight(context);
    final searchState = ref.watch(movieSearchProvider(_searchQuery));

    return AppScaffold(
      usePadding: true,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: headerHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: 24.h),
                    children: [
                      SizedBox(height: 8.h),
                      _SearchField(
                        controller: _controller,
                        focusNode: _focusNode,
                        hasText: _inputQuery.trim().isNotEmpty,
                        onChanged: _onQueryChanged,
                        onSubmitted: _submitSearch,
                        onClear: _clearSearch,
                      ),
                      SizedBox(height: 12.h),
                      _SearchBody(
                        query: _searchQuery,
                        searchState: searchState,
                        onMovieTap: _openMovieDetails,
                        onRetry: () {
                          ref.invalidate(movieSearchProvider(_searchQuery));
                        },
                      ),
                    ],
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
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final fieldHeight = isTablet ? 64.0 : 50.h;

    return Container(
      height: fieldHeight,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 10.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(width: isTablet ? 18 : 16.w),
          Image.asset(
            AppAssets.search,
            width: isTablet ? 26 : 20.w,
            height: isTablet ? 26 : 20.w,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: isTablet ? 14 : 12.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.primary,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 20 : 18.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                hintText: 'Search movies',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isTablet ? 18 : 17.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (hasText) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: isTablet ? 30 : 24.w,
                height: isTablet ? 30 : 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.68),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: isTablet ? 20 : 18.sp,
                  color: AppColors.background,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 18 : 16.w),
          ] else
            SizedBox(width: isTablet ? 18 : 16.w),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  final String query;
  final AsyncValue<List<Movie>> searchState;
  final ValueChanged<Movie> onMovieTap;
  final VoidCallback onRetry;

  const _SearchBody({
    required this.query,
    required this.searchState,
    required this.onMovieTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const _SearchMessage(
        icon: Icons.search_rounded,
        title: 'Search movies',
        message: 'Find a title by name, genre, country, language, or cast.',
      );
    }

    return searchState.when(
      data: (movies) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchResultHeader(query: query, count: movies.length),
            SizedBox(height: 14.h),
            if (movies.isEmpty)
              const _SearchMessage(
                icon: Icons.manage_search_rounded,
                title: 'No results found',
                message: 'Try another movie title or keyword.',
              )
            else
              ListView.separated(
                itemCount: movies.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (_, index) {
                  final movie = movies[index];

                  return _SearchResultCard(
                    movie: movie,
                    onTap: () => onMovieTap(movie),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const _SearchLoadingView(),
      error: (error, _) =>
          _SearchErrorView(message: error.toString(), onRetry: onRetry),
    );
  }
}

class _SearchResultHeader extends StatelessWidget {
  final String query;
  final int count;

  const _SearchResultHeader({required this.query, required this.count});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final resultLabel = count == 1 ? 'result' : 'results';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Results for '),
              TextSpan(
                text: '"$query"',
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 24 : 18.sp,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '$count $resultLabel found',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 17 : 15.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _SearchResultCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final cardHeight = isTablet ? 174.0 : 130.h;
    final imageWidth = isTablet ? 230.0 : 156.w;
    final horizontalPadding = isTablet ? 22.0 : 12.w;
    final scoreLabel = movie.scoreLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: imageWidth,
              height: double.infinity,
              child: AppImage(source: movie.displayPosterUrl),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isTablet ? 16 : 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 22 : 16.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    SizedBox(height: isTablet ? 8 : 5.h),
                    _MovieMetaRow(movie: movie),
                    SizedBox(height: isTablet ? 10 : 7.h),
                    Expanded(
                      child: Text(
                        movie.description,
                        maxLines: isTablet ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isTablet ? 15 : 12.sp,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 10 : 7.h),
                    Row(
                      children: [
                        if (scoreLabel != null) ...[
                          Icon(
                            Icons.star_rounded,
                            color: const Color(0xFFFFD21F),
                            size: isTablet ? 22 : 17.sp,
                          ),
                          SizedBox(width: isTablet ? 7 : 5.w),
                          Text(
                            scoreLabel,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: isTablet ? 16 : 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: isTablet ? 14 : 12.w),
                        ],
                        _AgePill(label: movie.ageRatingLabel),
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

class _MovieMetaRow extends StatelessWidget {
  final Movie movie;

  const _MovieMetaRow({required this.movie});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final metaStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: isTablet ? 15 : 12.sp,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );

    return Row(
      children: [
        if (movie.yearLabel.isNotEmpty) ...[
          Flexible(
            child: Text(
              movie.yearLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: metaStyle,
            ),
          ),
          _MetaDot(isTablet: isTablet),
        ],
        Flexible(
          child: Text(
            movie.durationLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: metaStyle,
          ),
        ),
        if (movie.genre.isNotEmpty) ...[
          _MetaDot(isTablet: isTablet),
          Expanded(
            child: Text(
              movie.genre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: metaStyle,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  final bool isTablet;

  const _MetaDot({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8.w),
      child: Container(
        width: isTablet ? 3 : 3.w,
        height: isTablet ? 3 : 3.w,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _AgePill extends StatelessWidget {
  final String label;

  const _AgePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 7.w,
        vertical: isTablet ? 4 : 3.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(isTablet ? 8 : 6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isTablet ? 14 : 11.sp,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _SearchLoadingView extends StatelessWidget {
  const _SearchLoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 74.h),
      child: Center(
        child: SizedBox(
          width: 30.w,
          height: 30.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _SearchErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SearchErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _SearchMessage(
      icon: Icons.wifi_off_rounded,
      title: 'Unable to search',
      message: message,
      actionLabel: 'Try Again',
      onActionTap: onRetry,
    );
  }
}

class _SearchMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(top: 70.h, left: 20.w, right: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            if (actionLabel != null && onActionTap != null) ...[
              SizedBox(height: 16.h),
              TextButton(
                onPressed: onActionTap,
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: isTablet ? 16 : 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
