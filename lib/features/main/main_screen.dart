import 'package:africanmovies/features/genres/genres_screen.dart';
import 'package:africanmovies/features/library/my_library_screen.dart';
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

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Widget _profileScreen() {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (session) {
        if (session == null) {
          return NonAuthProfileScreen(onTabSelected: _selectTab);
        }

        return ProfileScreen(
          user: session.user,
          onTabSelected: _selectTab,
          onSignOut: _signOut,
        );
      },
      error: (_, _) => NonAuthProfileScreen(onTabSelected: _selectTab),
      loading: () => const _ProfileLoadingScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const GenresScreen(),
      const WatchlistScreen(),
      const MyLibraryScreen(),
      _profileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
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
