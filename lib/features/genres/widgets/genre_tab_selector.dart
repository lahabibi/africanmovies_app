import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class GenreTabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const GenreTabSelector({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Genres', 'Languages'];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TabItem(
                label: tabs[0],
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),

            Container(
              width: 1.w,
              height: 18.h,
              color: AppColors.cardBorder,
            ),

            Expanded(
              child: _TabItem(
                label: tabs[1],
                selected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
        Divider(
          height: 1.h,
          color: AppColors.cardBorder,
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 46.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 12.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 92.w,
              height: 2.5.h,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(100.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}