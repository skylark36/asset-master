import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import '../widgets/add_asset_dialog.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/user_tab.dart';

class DashboardView extends GetView<PortfolioController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            controller.showFab.value = false;
          } else if (notification.direction == ScrollDirection.forward) {
            controller.showFab.value = true;
          }
          return false;
        },
        child: SafeArea(
          child: Obx(() {
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
        ),
      ),

      // Floating Action Button (Themed to native TDesign color)
      floatingActionButton: Obx(() {
        final isOverviewTab = controller.activeTab.value == 0;
        final isVisible = isOverviewTab && controller.showFab.value;
        return AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          offset: isVisible ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isVisible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isVisible,
              child: FloatingActionButton(
                onPressed: () {
                  Get.to(() => const AddAssetDialog());
                },
                backgroundColor: theme.brandNormalColor,
                elevation: 4,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ),
        );
      }),

      bottomNavigationBar: Obx(() {
        return TDBottomTabBar(
          TDBottomTabBarBasicType.iconText,
          currentIndex: controller.activeTab.value,
          backgroundColor: theme.bgColorContainer,
          componentType: TDBottomTabBarComponentType.normal,
          showTopBorder: true,
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
              selectTabTextStyle: TextStyle(
                color: theme.brandNormalColor,
                fontWeight: FontWeight.bold,
              ),
              unselectTabTextStyle: TextStyle(color: theme.textColorSecondary),
              onTap: () {
                controller.activeTab.value = 0;
                controller.showFab.value = true;
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
              selectTabTextStyle: TextStyle(
                color: theme.brandNormalColor,
                fontWeight: FontWeight.bold,
              ),
              unselectTabTextStyle: TextStyle(color: theme.textColorSecondary),
              onTap: () {
                controller.activeTab.value = 1;
                controller.showFab.value = true;
              },
            ),
          ],
        );
      }),
    );
  }
}
