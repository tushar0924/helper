import 'package:flutter/material.dart';

class MainBottomBar extends StatelessWidget {
  const MainBottomBar({
    super.key,
    required this.selectedTab,
    required this.onHomeTap,
    required this.onHelperTap,
    required this.onKiranaTap,
  });

  final MainTab selectedTab;
  final VoidCallback onHomeTap;
  final VoidCallback onHelperTap;
  final VoidCallback onKiranaTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FA),
          border: Border(
            top: BorderSide(color: Color(0xFFE3E6EA), width: 1),
          ),
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: selectedTab == MainTab.home,
              onTap: onHomeTap,
            ),
            _NavItem(
              icon: Icons.support_agent,
              label: 'Helperr4U',
              selected: selectedTab == MainTab.helper,
              onTap: onHelperTap,
            ),
            _NavItem(
              icon: Icons.storefront_outlined,
              label: 'Kirana4U',
              selected: selectedTab == MainTab.kirana,
              onTap: onKiranaTap,
            ),
          ],
        ),
      ),
    );
  }
}

enum MainTab {
  home,
  helper,
  kirana,
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : const Color(0xFF7C8796);
    final labelColor = selected ? const Color(0xFF0E1A2B) : const Color(0xFF7C8796);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0EA5C6) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
