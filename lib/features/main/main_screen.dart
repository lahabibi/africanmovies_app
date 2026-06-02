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

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  String? _selectedGenre;

  bool get _hasSession {
    return ref.read(authControllerProvider).asData?.value != null;
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleTabTap(int index) {
    if (_isProtectedTab(index) && !_hasSession) {
      _openAuth(onAuthenticated: () => _selectTab(index));
      return;
    }

    _selectTab(index);
  }

  bool _isProtectedTab(int index) {
    return index == 2 || index == 3;
  }

  void _openAuth({VoidCallback? onAuthenticated}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(onAuthenticated: onAuthenticated),
      ),
    );
  }

  void _openProtectedTab(int index) {
    if (_hasSession) {
      _selectTab(index);
      return;
    }

    _openAuth(onAuthenticated: () => _selectTab(index));
  }

  void _openProtectedRoute(WidgetBuilder builder) {
    if (_hasSession) {
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

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
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
      HomeScreen(onGenreSelected: _openGenreTab),
      GenresScreen(selectedGenre: _selectedGenre),
      const WatchlistScreen(),
      const MyLibraryScreen(),
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
