import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';

import '../widgets/dashboard_tab.dart';
import '../widgets/user_tab.dart';
import 'package:universal_html/html.dart' as html;

class DashboardView extends GetView<PortfolioController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    // Check if it's an installed PWA
    final isPwa =
        kIsWeb && html.window.matchMedia('(display-mode: standalone)').matches;
    // Check if it's web iOS
    final isWebiOS =
        kIsWeb &&
        html.window.navigator.userAgent.contains(RegExp(r'iPad|iPod|iPhone'));
    return Padding(
      padding: EdgeInsets.only(bottom: isPwa && isWebiOS ? 25 : 0),
      child: SafeArea(
        child: Scaffold(
          body: Obx(() {
            if (controller.isLoading.value && controller.portfolios.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.brandNormalColor),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing Portfolio Ledger...',
                      style: TextStyle(
                        color: theme.textColorSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            return IndexedStack(
              index: controller.activeTab.value,
              children: const [DashboardTab(), UserTab()],
            );
          }),
          bottomNavigationBar: Obx(() {
            return SizedBox(
              width: 400,
              child: TDBottomTabBar(
                TDBottomTabBarBasicType.iconText,
                currentIndex: controller.activeTab.value,
                showTopBorder: false,
                navigationTabs: [
                  TDBottomTabBarTabConfig(
                    tabText: 'Overview',
                    selectedIcon: Icon(
                      Icons.grid_view_rounded,
                      color: theme.brandNormalColor,
                    ),
                    unselectedIcon: Icon(
                      Icons.grid_view_rounded,
                      color: theme.textColorSecondary,
                    ),
                    onTap: () {
                      controller.activeTab.value = 0;
                    },
                  ),
                  TDBottomTabBarTabConfig(
                    tabText: 'Profile',
                    selectedIcon: Icon(
                      Icons.person_2_rounded,
                      color: theme.brandNormalColor,
                    ),
                    unselectedIcon: Icon(
                      Icons.person_2_rounded,
                      color: theme.textColorSecondary,
                    ),
                    onTap: () {
                      controller.activeTab.value = 1;
                    },
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
