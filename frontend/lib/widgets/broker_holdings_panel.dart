import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/portfolio_controller.dart';
import '../models/valuation.dart';
import '../theme/app_theme.dart';
import 'asset_list_table.dart';

class BrokerHoldingsPanel extends StatefulWidget {
  final String brokerName;
  final List<HoldingValuation> holdings;

  const BrokerHoldingsPanel({
    super.key,
    required this.brokerName,
    required this.holdings,
  });

  @override
  State<BrokerHoldingsPanel> createState() => _BrokerHoldingsPanelState();
}

class _BrokerHoldingsPanelState extends State<BrokerHoldingsPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PortfolioController>();
    final theme = TDTheme.of(context);
    final baseCurrencyCode =
        controller.selectedPortfolio.value?.currency ?? 'USD';
    final baseCurrencySymbol = AppTheme.getCurrencySymbol(baseCurrencyCode);
    final baseCurrencyFormatter = NumberFormat.currency(
      symbol: baseCurrencySymbol,
      decimalDigits: 2,
    );

    // Calculate sum of holdings under this broker
    final totalValue = widget.holdings.fold<double>(
      0.0,
      (sum, h) => sum + h.currentValue,
    );
    final totalCost = widget.holdings.fold<double>(
      0.0,
      (sum, h) => sum + h.costBasis,
    );
    final netReturn = totalValue - totalCost;
    final netReturnPercentage = totalCost > 0
        ? (netReturn / totalCost) * 100
        : 0.0;
    final isProfit = netReturn >= 0;
    final gainLossColor = isProfit
        ? theme.successNormalColor
        : theme.errorNormalColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.bgColorContainer,
        borderRadius: BorderRadius.circular(theme.radiusDefault),
        border: Border.all(color: theme.componentBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radiusDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Collapsible Header Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: Colors.black.withValues(
                    alpha: 0.02,
                  ), // Highly translucent glass header shine in light mode
                  child: Row(
                    children: [
                      // Animated Caret
                      RotationTransition(
                        turns: _iconRotationAnimation,
                        child: Icon(
                          Icons.keyboard_arrow_right_rounded,
                          color: theme.brandNormalColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Broker Name & Icon
                      Icon(
                        Icons.account_balance_outlined,
                        color: theme.textColorSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),

                      // Wrap name & badge in Expanded to scale down on small screens without overflow
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.brokerName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: theme.textColorPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right side Valuation quick metrics
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            baseCurrencyFormatter.format(totalValue),
                            style: TextStyle(
                              color: theme.textColorPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isProfit
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: gainLossColor,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${isProfit ? "+" : ""}${netReturnPercentage.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: gainLossColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expanded Table content
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.componentBorderColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: AssetListTable(
                        holdings: widget.holdings,
                        borderless: true, // Seamless fit in the unified card
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
