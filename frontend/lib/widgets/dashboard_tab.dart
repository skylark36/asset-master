import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import '../models/valuation.dart';
import 'add_asset_dialog.dart';
import 'portfolio_card.dart';
import 'allocation_chart.dart';
import 'broker_holdings_panel.dart';

class DashboardTab extends GetView<PortfolioController> {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => controller.refreshActivePortfolio(),
        color: theme.brandNormalColor,
        backgroundColor: theme.bgColorContainer,
        child: SingleChildScrollView(
          // physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(theme.spacer16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Obx(() {
                final valuation = controller.valuation.value;
                if (valuation == null) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.brandNormalColor,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Valuation update loading state indicator
                    if (controller.isValuationLoading.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          color: theme.brandNormalColor,
                          backgroundColor: Colors.transparent,
                        ),
                      ),

                    // Summary Cards & Allocation Chart
                    PortfolioCard(valuation: valuation),
                    const SizedBox(height: 16),
                    AllocationChart(valuation: valuation),

                    const SizedBox(height: 24),

                    // Holdings List Table grouped inside collapsible broker cards
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Holdings & Valuations',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.textColorPrimary,
                        ),
                      ),
                    ),

                    Builder(
                      builder: (context) {
                        final holdingsByBroker =
                            <String, List<HoldingValuation>>{};
                        for (var holding in valuation.holdings) {
                          holdingsByBroker
                              .putIfAbsent(holding.broker, () => [])
                              .add(holding);
                        }

                        if (holdingsByBroker.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(48),
                            decoration: BoxDecoration(
                              color: theme.bgColorContainer,
                              borderRadius: BorderRadius.circular(
                                theme.radiusMap['large'] ?? 12,
                              ),
                              border: Border.all(
                                color: theme.componentBorderColor,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No purchase records yet. Click "Add Record" to populate your portfolio.',
                                style: TextStyle(
                                  color: theme.textColorSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: holdingsByBroker.entries.map((entry) {
                            return BrokerHoldingsPanel(
                              brokerName: entry.key,
                              holdings: entry.value,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const AddAssetDialog());
        },
        backgroundColor: theme.brandNormalColor,
        elevation: 4,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
