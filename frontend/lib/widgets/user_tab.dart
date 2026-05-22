import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import '../controllers/auth_controller.dart';
import '../views/login_view.dart';
import '../views/purchase_history_view.dart';
import '../views/feedback_view.dart';
import '../views/manage_brokers_view.dart';

class UserTab extends GetView<PortfolioController> {
  const UserTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final theme = TDTheme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: isMobile ? 16 : 32,
        right: isMobile ? 16 : 32,
        top: 24,
        bottom: isMobile ? 80 : 24,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Obx(() {
            final user = authController.currentUser.value;
            final String name = user?.name ?? 'User';
            final String email = user?.email ?? '';
            final String initial = name.isNotEmpty
                ? name[0].toUpperCase()
                : 'U';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. User Info Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.bgColorContainer,
                    borderRadius: BorderRadius.circular(
                      theme.radiusMap['large'] ?? 12,
                    ),
                    border: Border.all(
                      color: theme.componentBorderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Pulsing Avatar with iOS Neon Ring
                      Container(
                        width: 88,
                        height: 88,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.brandNormalColor,
                          boxShadow: [
                            BoxShadow(
                              color: theme.brandNormalColor.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme
                                .bgColorContainer, // Adaptive background inside ring
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.brandNormalColor,
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        name,
                        style: TextStyle(
                          color: theme.textColorPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: theme.textColorSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Glassmorphic Red Logout Button
                      TDButton(
                        onTap: () async {
                          await authController.logout();
                          Get.offAll(
                            () => const LoginView(),
                            transition: Transition.fadeIn,
                          );
                        },
                        size: TDButtonSize.large,
                        type: TDButtonType.outline,
                        theme: TDButtonTheme.danger,
                        isBlock: true,
                        icon: Icons.logout_rounded,
                        text: 'Sign Out of Ledger',
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.errorNormalColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Navigation Entries
                Container(
                  decoration: BoxDecoration(
                    color: theme.bgColorContainer,
                    borderRadius: BorderRadius.circular(
                      theme.radiusMap['large'] ?? 12,
                    ),
                    border: Border.all(
                      color: theme.componentBorderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildNavigationEntry(
                        context: context,
                        icon: Icons.receipt_long_outlined,
                        title: 'Purchase History',
                        subtitle: 'View and filter all holding records',
                        iconColor: theme.brandNormalColor,
                        onTap: () => Get.to(
                          () => const PurchaseHistoryView(),
                          transition: Transition.rightToLeft,
                        ),
                      ),
                      Divider(color: theme.componentBorderColor, height: 1),
                      _buildNavigationEntry(
                        context: context,
                        icon: Icons.monetization_on_outlined,
                        title: 'Base Currency',
                        subtitle:
                            'Change aggregate portfolio reporting currency',
                        iconColor: theme.brandNormalColor,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.brandNormalColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.brandNormalColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            controller.selectedPortfolio.value?.currency ??
                                'USD',
                            style: TextStyle(
                              color: theme.brandNormalColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _showCurrencySelectorDialog(context),
                      ),
                      Divider(color: theme.componentBorderColor, height: 1),
                      _buildNavigationEntry(
                        context: context,
                        icon: Icons.account_balance_outlined,
                        title: 'Manage Brokers',
                        subtitle: 'Configure preset and custom brokers',
                        iconColor: theme.brandNormalColor,
                        onTap: () => Get.to(
                          () => const ManageBrokersView(),
                          transition: Transition.rightToLeft,
                        ),
                      ),
                      Divider(color: theme.componentBorderColor, height: 1),
                      _buildNavigationEntry(
                        context: context,
                        icon: Icons.rate_review_outlined,
                        title: 'Share Feedback',
                        subtitle: 'Help us improve Asset Master',
                        iconColor: theme.brandNormalColor,
                        onTap: () => Get.to(
                          () => const FeedbackView(),
                          transition: Transition.rightToLeft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showCurrencySelectorDialog(BuildContext context) {
    final theme = TDTheme.of(context);
    final List<Map<String, String>> currencies = [
      {'code': 'USD', 'name': 'United States Dollar', 'symbol': r'$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': r'A$'},
      {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': r'C$'},
      {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'Fr'},
      {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': r'HK$'},
      {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
      {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': r'S$'},
    ];

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.radiusMap['large'] ?? 12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.bgColorContainer,
                borderRadius: BorderRadius.circular(
                  theme.radiusMap['large'] ?? 12,
                ),
                border: Border.all(color: theme.componentBorderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Base Currency',
                        style: TextStyle(
                          color: theme.textColorPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.textColorSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Changing the base currency updates all calculations and live price conversions across the app.',
                    style: TextStyle(
                      color: theme.textColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: currencies.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: theme.componentBorderColor, height: 1),
                      itemBuilder: (context, index) {
                        final curr = currencies[index];
                        final code = curr['code']!;
                        final name = curr['name']!;
                        final sym = curr['symbol']!;
                        final isSelected =
                            controller.selectedPortfolio.value?.currency
                                .toUpperCase() ==
                            code;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              Get.back(); // close dialog
                              final success = await controller
                                  .updateSelectedPortfolioCurrency(code);
                              if (success) {
                                Get.snackbar(
                                  'Currency Updated',
                                  'Portfolio base currency is now $code ($sym).',
                                  backgroundColor: theme.bgColorContainer,
                                  colorText: theme.textColorPrimary,
                                  borderColor: theme.brandNormalColor,
                                  borderWidth: 1,
                                  snackPosition: SnackPosition.BOTTOM,
                                  maxWidth: 320,
                                  margin: const EdgeInsets.only(bottom: 24),
                                );
                              } else {
                                Get.snackbar(
                                  'Error',
                                  'Failed to update base currency.',
                                  backgroundColor: theme.errorNormalColor
                                      .withValues(alpha: 0.1),
                                  colorText: theme.errorNormalColor,
                                  borderColor: theme.errorNormalColor,
                                  borderWidth: 1,
                                  snackPosition: SnackPosition.BOTTOM,
                                  maxWidth: 320,
                                  margin: const EdgeInsets.only(bottom: 24),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.brandNormalColor.withValues(
                                              alpha: 0.15,
                                            )
                                          : theme.componentBorderColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.brandNormalColor
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        sym,
                                        style: TextStyle(
                                          color: isSelected
                                              ? theme.brandNormalColor
                                              : theme.textColorPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          code,
                                          style: TextStyle(
                                            color: theme.textColorPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: theme.textColorSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.brandNormalColor,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.6),
    );
  }

  Widget _buildNavigationEntry({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = TDTheme.of(context);
    return TDCell(
      title: title,
      description: subtitle,
      style: TDCellStyle(
        backgroundColor: Colors.transparent,
        clickBackgroundColor: theme.componentBorderColor.withValues(
          alpha: 0.05,
        ),
        titleStyle: TextStyle(
          color: theme.textColorPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
        descriptionStyle: TextStyle(
          color: theme.textColorSecondary,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      ),
      leftIconWidget: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      noteWidget: trailing,
      arrow: true,
      onClick: (_) => onTap(),
    );
  }
}
