import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/portfolio_controller.dart';
import '../models/valuation.dart';
import '../theme/app_theme.dart';
import '../views/asset_detail_view.dart';

class AssetListTable extends StatelessWidget {
  final List<HoldingValuation> holdings;
  final bool borderless;

  const AssetListTable({
    super.key,
    required this.holdings,
    this.borderless = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PortfolioController>();
    final theme = TDTheme.of(context);
    final baseCurrencyCode = controller.selectedPortfolio.value?.currency ?? 'USD';
    final baseCurrencySymbol = AppTheme.getCurrencySymbol(baseCurrencyCode);
    final baseCurrencyFormatter = NumberFormat.currency(
      symbol: baseCurrencySymbol,
      decimalDigits: 2,
    );
    final percentFormatter = NumberFormat.decimalPercentPattern(
      decimalDigits: 2,
    );

    if (holdings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.bgColorContainer,
          borderRadius: BorderRadius.circular(theme.radiusMap['medium'] ?? 8),
          border: Border.all(color: theme.componentBorderColor, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 28,
                color: theme.textColorSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                'No holdings in this portfolio yet.',
                style: TextStyle(
                  color: theme.textColorPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Click the "+" button to start adding purchases.',
                style: TextStyle(color: theme.textColorSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 1000.0;
        final tableWidth = constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;

        final childWidget = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Colors.black.withValues(alpha: 0.02),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildHeaderCell(theme, 'ASSET')),
                      Expanded(flex: 2, child: _buildHeaderCell(theme, 'HOLDINGS')),
                      Expanded(flex: 3, child: _buildHeaderCell(theme, 'AVG PRICE')),
                      Expanded(
                        flex: 3,
                        child: _buildHeaderCell(theme, 'CURRENT PRICE'),
                      ),
                      Expanded(flex: 3, child: _buildHeaderCell(theme, 'COST BASIS')),
                      Expanded(
                        flex: 3,
                        child: _buildHeaderCell(theme, 'MARKET VALUE'),
                      ),
                      Expanded(flex: 3, child: _buildHeaderCell(theme, 'GAIN / LOSS')),
                      const SizedBox(
                        width: 32,
                      ), // Spacing matching the chevron icon
                    ],
                  ),
                ),

                // Data Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: holdings.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: theme.componentBorderColor, height: 1),
                  itemBuilder: (context, index) {
                    final holding = holdings[index];
                    final localCurrencySymbol = AppTheme.getCurrencySymbol(
                      holding.currency,
                    );
                    final localCurrencyFormatter = NumberFormat.currency(
                      symbol: localCurrencySymbol,
                      decimalDigits: 2,
                    );

                    final profitLoss = holding.profitLoss;
                    final profitLossPercentage =
                        holding.profitLossPercentage / 100.0;
                    final isProfit = profitLoss >= 0;
                    final gainLossColor = isProfit
                        ? theme.successNormalColor
                        : theme.errorNormalColor;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Get.to(() => AssetDetailView(symbol: holding.symbol));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // ASSET badge and Name
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.brandNormalColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        holding.symbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        holding.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: theme.textColorPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // HOLDINGS (QUANTITY)
                              Expanded(
                                flex: 2,
                                child: Text(
                                  holding.quantity.toString(),
                                  style: TextStyle(
                                    color: theme.textColorPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              // AVG PURCHASE PRICE
                              Expanded(
                                flex: 3,
                                child: Text(
                                  localCurrencyFormatter.format(
                                    holding.purchasePrice,
                                  ),
                                  style: TextStyle(
                                    color: theme.textColorPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              // CURRENT PRICE
                              Expanded(
                                flex: 3,
                                child: Text(
                                  localCurrencyFormatter.format(
                                    holding.currentPrice,
                                  ),
                                  style: TextStyle(
                                    color: theme.textColorPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              // COST BASIS
                              Expanded(
                                flex: 3,
                                child: Text(
                                  baseCurrencyFormatter.format(
                                    holding.costBasis,
                                  ),
                                  style: TextStyle(
                                    color: theme.textColorPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              // MARKET VALUE
                              Expanded(
                                flex: 3,
                                child: Text(
                                  baseCurrencyFormatter.format(
                                    holding.currentValue,
                                  ),
                                  style: TextStyle(
                                    color: theme.textColorPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              // GAIN / LOSS
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${isProfit ? "+" : ""}${baseCurrencyFormatter.format(profitLoss)}',
                                      style: TextStyle(
                                        color: gainLossColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '${isProfit ? "+" : ""}${percentFormatter.format(profitLossPercentage)}',
                                      style: TextStyle(
                                        color: gainLossColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Chevron arrow forward
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.textColorSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );

        if (borderless) {
          return childWidget;
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.bgColorContainer,
            borderRadius: BorderRadius.circular(theme.radiusMap['medium'] ?? 8),
            border: Border.all(color: theme.componentBorderColor, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.radiusMap['medium'] ?? 8),
            child: childWidget,
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(TDThemeData theme, String label) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: theme.textColorSecondary,
          fontSize: 9,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
