import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  int _getSelectedIndex(String location) {
    if (location.startsWith('/chat')) return 0;
    if (location.startsWith('/avatar-builder')) return 1;
    if (location.startsWith('/topic-picker')) return 2;
    if (location.startsWith('/memories')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/chat');
        break;
      case 1:
        context.go('/avatar-builder');
        break;
      case 2:
        context.go('/topic-picker');
        break;
      case 3:
        context.go('/memories');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.record_voice_over_rounded,
              label: 'Voice AI',
              isSelected: selectedIndex == 0,
              onTap: () => _onItemTapped(0, context),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.face_retouching_natural_rounded,
              label: 'Companion',
              isSelected: selectedIndex == 1,
              onTap: () => _onItemTapped(1, context),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.category_rounded,
              label: 'Topics',
              isSelected: selectedIndex == 2,
              onTap: () => _onItemTapped(2, context),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.psychology_rounded,
              label: 'Memory',
              isSelected: selectedIndex == 3,
              onTap: () => _onItemTapped(3, context),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              isSelected: selectedIndex == 4,
              onTap: () => _onItemTapped(4, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
