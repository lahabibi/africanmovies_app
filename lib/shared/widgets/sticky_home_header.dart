import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/home/widgets/home_header.dart';

class StickyHomeHeader extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 56.h;

  @override
  double get maxExtent => 56.h;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(top: 10.h),
      child: const HomeHeader(),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}