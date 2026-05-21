import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../models/valuation.dart';

class AllocationChart extends StatefulWidget {
  final PortfolioValuation valuation;
  final double? height;

  const AllocationChart({super.key, required this.valuation, this.height});

  @override
  State<AllocationChart> createState() => _AllocationChartState();
}

class _AllocationChartState extends State<AllocationChart> {
  int touchedIndex = -1;

  // Modern vibrant colors list for sectors
  final List<Color> sectorColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF00F0FF), // Cyber Cyan
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF97316), // Orange
    const Color(0xFFF43F5E), // Red
  ];

  @override
  Widget build(BuildContext context) {
    final holdings = widget.valuation.holdings;
    final theme = TDTheme.of(context);

    if (holdings.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        height: widget.height ?? 220,
        decoration: BoxDecoration(
          color: theme.bgColorContainer,
          borderRadius: BorderRadius.circular(theme.radiusMap['large'] ?? 12),
          border: Border.all(color: theme.componentBorderColor, width: 1),
        ),
        child: Center(
          child: Text(
            'Add assets to see allocation',
            style: TextStyle(color: theme.textColorSecondary),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
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
        children: [
          Text(
            'ASSET ALLOCATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: theme.textColorSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 32,
                    sections: showingSections(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: holdings.length,
                  itemBuilder: (context, index) {
                    final holding = holdings[index];
                    final color = sectorColors[index % sectorColors.length];
                    final isTouched = index == touchedIndex;
 
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              holding.symbol,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
                                color: isTouched ? theme.textColorPrimary : theme.textColorSecondary,
                              ),
                            ),
                          ),
                          Text(
                            '${holding.weightPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
                              color: isTouched ? theme.textColorPrimary : theme.textColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  List<PieChartSectionData> showingSections() {
    final holdings = widget.valuation.holdings;
    return List.generate(holdings.length, (i) {
      final holding = holdings[i];
      final isTouched = i == touchedIndex;
      final double fontSize = isTouched ? 13.0 : 10.0;
      final double radius = isTouched ? 18.0 : 14.0;
      final color = sectorColors[i % sectorColors.length];
 
      return PieChartSectionData(
        color: color,
        value: holding.weightPercentage,
        title: isTouched ? '${holding.weightPercentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}
