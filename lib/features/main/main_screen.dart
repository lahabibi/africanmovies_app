import 'package:africanmovies/features/auth/auth_screen.dart';
import 'package:africanmovies/features/favorite/favorite_screen.dart';
import 'package:africanmovies/features/genres/genres_screen.dart';
import 'package:africanmovies/features/library/my_library_screen.dart';
import 'package:africanmovies/features/profile/devices_screen.dart';
import 'package:africanmovies/features/profile/profile_screen.dart';
import 'package:africanmovies/features/profile/non_auth_profile_screen.dart';
import 'package:africanmovies/features/watchlist/watchlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../auth/application/auth_controller.dart';
import '../home/home_screen.dart';
import '../payment/application/native_purchase_recovery_controller.dart';
import '../payment/application/payment_providers.dart';
import '../payment/domain/purchase_result.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _selectedGenre;
  bool _isValidatingSession = false;
  final Set<String> _libraryRedirectPurchaseKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ref.listenManual(authControllerProvider, (previous, next) {
      final hadSession = previous?.asData?.value != null;
      final hasSession = next.asData?.value != null;
      final hasNoSession = next.hasValue && next.asData?.value == null;

      if (hadSession && hasNoSession && _isProtectedTab(_currentIndex)) {
        setState(() => _currentIndex = 4);
      }

      if (!hadSession && hasSession) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _validateSessionIfSignedIn();
          ref
              .read(nativePurchaseRecoveryControllerProvider.notifier)
              .recoverOutstandingPurchases();
        });
      }
    });

    ref.listenManual(nativePurchaseRecoveryControllerProvider, (
      previous,
      next,
    ) {
      final notice = next.asData?.value;
      if (notice == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentNotice = ref
            .read(nativePurchaseRecoveryControllerProvider)
            .asData
            ?.value;
        if (currentNotice?.transactionKey != notice.transactionKey) return;

        _showMessage(notice.message);
        ref
            .read(nativePurchaseRecoveryControllerProvider.notifier)
            .clearNotice();
      });
    });

    ref.listenManual(purchaseControllerProvider, (previous, next) {
      final result = next.asData?.value;
      if (result == null || !result.grantsAccess) return;

      ref
          .read(nativePurchaseRecoveryControllerProvider.notifier)
          .markPurchaseHandled(
            txRef: result.txRef,
            transactionId: result.transactionId,
          );

      if (result.status != PurchaseResultStatus.success) return;

      final redirectKey = result.transactionId?.trim().isNotEmpty == true
          ? result.transactionId!.trim()
          : result.txRef?.trim() ?? '';
      if (redirectKey.isEmpty ||
          !_libraryRedirectPurchaseKeys.add(redirectKey)) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.of(context).popUntil((route) => route.isFirst);
        setState(() => _currentIndex = 3);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateSessionIfSignedIn();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSessionIfSignedIn();
      ref
          .read(nativePurchaseRecoveryControllerProvider.notifier)
          .recoverOutstandingPurchases();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _hasSession {
    return ref.read(authControllerProvider).asData?.value != null;
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _handleTabTap(int index) async {
    if (_isProtectedTab(index) && !_hasSession) {
      _openAuth(onAuthenticated: () => _selectTab(index));
      return;
    }

    if (_shouldValidateBeforeOpening(index)) {
      final isValid = await _validateSessionIfSignedIn();
      if (!mounted) return;
      if (!isValid) {
        _selectTab(4);
        return;
      }
    }

    _selectTab(index);
  }

  bool _isProtectedTab(int index) {
    return index == 2 || index == 3;
  }

  bool _shouldValidateBeforeOpening(int index) {
    return _isProtectedTab(index) || index == 4;
  }

  void _openAuth({VoidCallback? onAuthenticated}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(onAuthenticated: onAuthenticated),
      ),
    );
  }

  Future<void> _openProtectedTab(int index) async {
    if (_hasSession) {
      final isValid = await _validateSessionIfSignedIn();
      if (!mounted) return;
      if (!isValid) {
        _selectTab(4);
        return;
      }

      _selectTab(index);
      return;
    }

    _openAuth(onAuthenticated: () => _selectTab(index));
  }

  Future<void> _openProtectedRoute(WidgetBuilder builder) async {
    if (_hasSession) {
      final isValid = await _validateSessionIfSignedIn();
      if (!mounted) return;
      if (!isValid) {
        _selectTab(4);
        return;
      }

      Navigator.push(context, MaterialPageRoute(builder: builder));
      return;
    }

    _openAuth(
      onAuthenticated: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: builder));
        });
      },
    );
  }

  void _openGenreTab(String genre) {
    setState(() {
      _selectedGenre = genre;
      _currentIndex = 1;
    });
  }

  void _openGenresTab() {
    setState(() {
      _selectedGenre = null;
      _currentIndex = 1;
    });
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<bool> _validateSessionIfSignedIn() async {
    if (!_hasSession) return false;
    if (_isValidatingSession) return true;

    _isValidatingSession = true;
    try {
      return await ref
          .read(authControllerProvider.notifier)
          .validateCurrentSession();
    } finally {
      _isValidatingSession = false;
    }
  }

  Widget _profileScreen() {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (session) {
        if (session == null) {
          return NonAuthProfileScreen(
            onTabSelected: _selectTab,
            onLoginRequested: () => _openAuth(),
            onLibraryRequested: () => _openProtectedTab(3),
            onFavoritesRequested: () {
              _openProtectedRoute((_) => const FavoriteScreen());
            },
            onWatchlistRequested: () => _openProtectedTab(2),
            onDevicesRequested: () {
              _openProtectedRoute((_) => const LoggedInDevicesScreen());
            },
          );
        }

        return ProfileScreen(
          user: session.user,
          onTabSelected: _selectTab,
          onSignOut: _signOut,
        );
      },
      error: (_, _) => NonAuthProfileScreen(
        onTabSelected: _selectTab,
        onLoginRequested: () => _openAuth(),
        onLibraryRequested: () => _openProtectedTab(3),
        onFavoritesRequested: () {
          _openProtectedRoute((_) => const FavoriteScreen());
        },
        onWatchlistRequested: () => _openProtectedTab(2),
        onDevicesRequested: () {
          _openProtectedRoute((_) => const LoggedInDevicesScreen());
        },
      ),
      loading: () => const _ProfileLoadingScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onGenreSelected: _openGenreTab,
        onGenresRequested: _openGenresTab,
      ),
      GenresScreen(selectedGenre: _selectedGenre),
      WatchlistScreen(onBrowseMovies: () => _selectTab(0)),
      MyLibraryScreen(onBrowseMovies: () => _selectTab(0)),
      _profileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleTabTap,
      ),
    );
  }
}

class _ProfileLoadingScreen extends StatelessWidget {
  const _ProfileLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
