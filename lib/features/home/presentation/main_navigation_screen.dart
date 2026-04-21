import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/category_provider.dart';
import 'home_screen.dart';
import 'home_tab_screen.dart';
import 'widgets/main_bottom_bar.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  MainTab _selectedTab = MainTab.helper;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryControllerProvider.notifier).loadCategories();
    });
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case MainTab.home:
        return const HomeTabScreen();
      case MainTab.helper:
        return const HelperTabView();
      case MainTab.kirana:
        return const _ComingSoonTab(label: 'Kirana4U');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<MainTab>(_selectedTab),
          child: _buildCurrentTab(),
        ),
      ),
      bottomNavigationBar: MainBottomBar(
        selectedTab: _selectedTab,
        onHomeTap: () {
          if (_selectedTab != MainTab.home) {
            setState(() {
              _selectedTab = MainTab.home;
            });
          }
        },
        onHelperTap: () {
          if (_selectedTab != MainTab.helper) {
            setState(() {
              _selectedTab = MainTab.helper;
            });
          }
        },
        onKiranaTap: () {
          if (_selectedTab != MainTab.kirana) {
            setState(() {
              _selectedTab = MainTab.kirana;
            });
          }
        },
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label Coming soon',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F2A47),
        ),
      ),
    );
  }
}
