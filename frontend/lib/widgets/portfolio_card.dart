import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:intl/intl.dart';
import '../models/valuation.dart';
import '../theme/app_theme.dart';

class PortfolioCard extends StatelessWidget {
  final PortfolioValuation valuation;
  final double? height;

  const PortfolioCard({super.key, required this.valuation, this.height});

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    final currencySymbol = AppTheme.getCurrencySymbol(valuation.currency);
    final currencyFormatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    final percentFormatter = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    
    final profitLoss = valuation.totalProfitLoss;
    final profitLossPercentage = valuation.totalProfitLossPercentage / 100.0;
    final isProfit = profitLoss >= 0;
    final color = isProfit ? theme.successNormalColor : theme.errorNormalColor;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.bgColorContainer,
        borderRadius: BorderRadius.circular(theme.radiusMap['medium'] ?? 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL NET WORTH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.textColorSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: color,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isProfit ? "+" : ""}${percentFormatter.format(profitLossPercentage)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Current Value
              Text(
                currencyFormatter.format(valuation.totalCurrentValue),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: theme.textColorPrimary,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
          
          Column(
            children: [
              Divider(color: theme.componentBorderColor, height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVESTMENT',
                          style: TextStyle(
                            color: theme.textColorSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(valuation.totalCostBasis),
                          style: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL GAIN/LOSS',
                          style: TextStyle(
                            color: theme.textColorSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isProfit ? "+" : ""}${currencyFormatter.format(profitLoss)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
