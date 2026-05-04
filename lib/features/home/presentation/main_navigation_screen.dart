import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_router.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/presentation/widgets/clear_cart_dialog.dart';
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
  bool _isCartBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryControllerProvider.notifier).loadCategories();
      ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);
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
    final cartState = ref.watch(cartProvider);
    final summary = cartState.summary;
    final itemCount = summary?.items.length ?? 0;
    final showFloatingCart = itemCount > 0 && !_isCartBannerDismissed;

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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFloatingCart)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x66D8DDE5), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$itemCount ${itemCount == 1 ? 'item' : 'items'} added',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatInr(summary?.pricing.total ?? 0),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 33,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRouter.cart);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0B1F3A),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'View Cart',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          final shouldClear = await showClearCartDialog(
                            context,
                            onConfirm: () {
                              return ref
                                  .read(cartProvider.notifier)
                                  .clearCart();
                            },
                          );
                          if (!mounted || !shouldClear) {
                            return;
                          }
                          setState(() {
                            _isCartBannerDismissed = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.cancel,
                            size: 18,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          MainBottomBar(
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
        ],
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
