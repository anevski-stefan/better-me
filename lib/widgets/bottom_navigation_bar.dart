import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               Expanded(
                 child: _buildNavItem(
                   context,
                   icon: Iconsax.home_2,
                   activeIcon: Iconsax.home_2,
                   label: 'Home',
                   index: 0,
                 ),
               ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Iconsax.chart_2,
                  activeIcon: Iconsax.chart_2,
                  label: 'Systems',
                  index: 1,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Iconsax.tick_circle,
                  activeIcon: Iconsax.tick_circle,
                  label: 'Habits',
                  index: 2,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Iconsax.flag,
                  activeIcon: Iconsax.flag,
                  label: 'Goals',
                  index: 3,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Iconsax.profile_2user,
                  activeIcon: Iconsax.profile_2user,
                  label: 'Settings',
                  index: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        print('GestureDetector tapped for index: $index');
        onTap(index);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodySmall?.color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
