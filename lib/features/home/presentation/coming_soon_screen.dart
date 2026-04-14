import 'package:flutter/material.dart';

import '../../../routes/app_router.dart';
import 'widgets/main_bottom_bar.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.selectedTab,
    required this.pageLabel,
  });

  final MainTab selectedTab;
  final String pageLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: Text(
          '$pageLabel Coming soon',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2A47),
          ),
        ),
      ),
      bottomNavigationBar: MainBottomBar(
        selectedTab: selectedTab,
        onHomeTap: () {
          if (selectedTab != MainTab.home) {
            Navigator.of(context).pushReplacementNamed(AppRouter.homeComingSoon);
          }
        },
        onHelperTap: () {
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        },
        onKiranaTap: () {
          if (selectedTab != MainTab.kirana) {
            Navigator.of(context).pushReplacementNamed(AppRouter.kiranaComingSoon);
          }
        },
      ),
    );
  }
}
