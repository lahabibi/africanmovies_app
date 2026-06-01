import 'package:africanmovies/features/genres/genres_screen.dart';
import 'package:africanmovies/features/library/my_library_screen.dart';
import 'package:africanmovies/features/profile/non_auth_profile_screen.dart';
import 'package:africanmovies/features/profile/profile_screen.dart';
import 'package:africanmovies/features/watchlist/watchlist_screen.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final _screens = [
    const HomeScreen(),
    const GenresScreen(),
    const WatchlistScreen(),
    const MyLibraryScreen(),
    ProfileScreen(
      onTabSelected: (index) {
        setState(() => _currentIndex = index);
      },
    ),
    // NonAuthProfileScreen(
    //     onTabSelected: (index) {
    //       setState(() => _currentIndex = index);
    //     },
    // )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title),
    );
  }
}