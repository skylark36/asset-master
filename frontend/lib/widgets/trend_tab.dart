import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import '../models/trend_data.dart';
import '../theme/app_theme.dart';

class TrendTab extends GetView<PortfolioController> {
  const TrendTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Obx(() {
      if (controller.isTrendLoading.value && controller.trendData.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.brandNormalColor),
              const SizedBox(height: 16),
              Text(
                'Analyzing historical trends...',
                style: TextStyle(
                  color: theme.textColorSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      final trendList = controller.trendData;
      if (trendList.isEmpty) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: theme.bgColorContainer,
              borderRadius: BorderRadius.circular(theme.radiusMap['large'] ?? 12),
              border: Border.all(color: theme.componentBorderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart_rounded, size: 64, color: theme.textColorPlaceholder),
                const SizedBox(height: 16),
                Text(
                  'No historical trend data available.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColorPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add assets to this portfolio to begin generating historical valuations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Calculate performance metrics over the trend window
      final double firstVal = trendList.first.value;
      final double lastVal = trendList.last.value;
      final double change = lastVal - firstVal;
      final double changePercent = firstVal > 0 ? (change / firstVal) * 100 : 0.0;
      final bool isPositive = change >= 0;

      final currencySymbol = AppTheme.getCurrencySymbol(controller.valuation.value?.currency ?? 'USD');
      final gainLossColor = isPositive ? theme.successNormalColor : theme.errorNormalColor;

      return SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: isMobile ? 80 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'VALUATION TREND',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.textColorSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Performance Cards
            Row(
              children: [
                // Total Valuation
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.bgColorContainer,
                      borderRadius: BorderRadius.circular(theme.radiusMap['large'] ?? 12),
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
                      children: [
                        Text(
                          'Current Value',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currencySymbol${lastVal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: theme.textColorPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 30D Performance Change
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.bgColorContainer,
                      borderRadius: BorderRadius.circular(theme.radiusMap['large'] ?? 12),
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
                      children: [
                        Text(
                          '30D Trend Change',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              color: gainLossColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${isPositive ? "+" : ""}${changePercent.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: gainLossColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Line Chart Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.bgColorContainer,
                borderRadius: BorderRadius.circular(theme.radiusMap['large'] ?? 12),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HISTORICAL VALUE (30D)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.textColorSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (controller.isTrendLoading.value)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.brandNormalColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 300,
                    child: _buildLineChart(theme, trendList, currencySymbol),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLineChart(TDThemeData theme, List<TrendDataPoint> trendList, String currencySymbol) {
    // 1. Generate Spots
    final List<FlSpot> spots = [];
    for (int i = 0; i < trendList.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendList[i].value));
    }

    // 2. Compute min/max for boundaries
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Padding values on Y axis
    double yPadding = (maxY - minY) * 0.15;
    if (yPadding == 0) yPadding = 10;
    minY = minY - yPadding;
    if (minY < 0) minY = 0;
    maxY = maxY + yPadding;

    // Interval settings for gridlines
    final double yInterval = (maxY - minY) / 5;

    // Dynamic horizontal labels formatting (MM-DD)
    final int labelInterval = (spots.length / 5).ceil();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.componentBorderColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx < 0 || idx >= trendList.length) {
                  return const SizedBox.shrink();
                }
                
                // Show labels at spaced intervals to prevent overlap
                if (idx % labelInterval == 0 || idx == trendList.length - 1) {
                  final String dateStr = trendList[idx].date;
                  final String displayDate = dateStr.length > 5 ? dateStr.substring(5) : dateStr; // MM-DD
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      displayDate,
                      style: TextStyle(
                        color: theme.textColorSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yInterval,
              reservedSize: 64,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink(); // Hide edge cases
                }
                
                // Format shorthand metric representations (e.g. 24K, 1.2M)
                String formatted = '';
                if (value >= 1000000) {
                  formatted = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  formatted = '${(value / 1000).toStringAsFixed(0)}K';
                } else {
                  formatted = value.toStringAsFixed(0);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '$currencySymbol$formatted',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: theme.textColorSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.componentBorderColor, width: 1),
        ),
        minX: 0,
        maxX: (trendList.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => theme.textColorPrimary.withValues(alpha: 0.9),
            tooltipRoundedRadius: 12,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final dateStr = trendList[touchedSpot.x.toInt()].date;
                final val = touchedSpot.y;
                return LineTooltipItem(
                  '$dateStr\n$currencySymbol${val.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.brandNormalColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.brandNormalColor.withValues(alpha: 0.25),
                  theme.brandNormalColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
