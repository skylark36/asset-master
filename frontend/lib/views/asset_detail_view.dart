import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/portfolio_controller.dart';
import '../models/valuation.dart';
import '../theme/app_theme.dart'; // Keep only for getCurrencySymbol static helper
import '../widgets/add_asset_dialog.dart';

class AssetDetailView extends StatelessWidget {
  final String symbol;
  final RxString selectedBrokerFilter = 'All'.obs;

  AssetDetailView({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PortfolioController>();
    final theme = TDTheme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: theme.bgColorPage,
      appBar: AppBar(
        backgroundColor: theme.bgColorContainer,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textColorPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '$symbol Details',
          style: TextStyle(
            color: theme.textColorPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.brandNormalColor),
            tooltip: 'Add Transaction',
            onPressed: () {
              Get.to(() => AddAssetDialog(prefilledSymbol: symbol));
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.componentBorderColor, height: 1),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final valuation = controller.valuation.value;
          if (valuation == null) {
            return Center(
              child: CircularProgressIndicator(color: theme.brandNormalColor),
            );
          }

          // Find reactive holding matching this symbol
          final holding = valuation.holdings.firstWhereOrNull(
            (h) => h.symbol.toUpperCase() == symbol.toUpperCase(),
          );

          if (holding == null) {
            // Automatically return to dashboard if no records left
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Get.currentRoute == '/AssetDetailView' ||
                  Get.isDialogOpen == false) {
                Get.back();
              }
            });
            return Center(
              child: CircularProgressIndicator(color: theme.brandNormalColor),
            );
          }

          final records = controller.assets
              .where((a) => a.symbol.toUpperCase() == symbol.toUpperCase())
              .toList();
          // Sort from new to old (newest first)
          records.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

          // Generate unique list of brokers present in these records
          final uniqueBrokers = records.map((r) => r.broker).toSet().toList();

          // Compute conversion factor from local currency to portfolio base currency
          double totalOverallLocalCostBasis = records.fold(
            0.0,
            (sum, r) => sum + (r.quantity * r.purchasePrice),
          );
          double conversionFactor = 1.0;
          if (totalOverallLocalCostBasis > 0) {
            conversionFactor = holding.costBasis / totalOverallLocalCostBasis;
          }

          // Compute market value exchange rate conversion factor
          double marketValueConversionFactor = 1.0;
          if (holding.quantity * holding.currentPrice > 0) {
            marketValueConversionFactor =
                holding.currentValue /
                (holding.quantity * holding.currentPrice);
          }

          // Filter records by selected broker
          final filteredRecords = selectedBrokerFilter.value == 'All'
              ? records
              : records
                    .where((r) => r.broker == selectedBrokerFilter.value)
                    .toList();

          // Recalculate metrics for filtered records
          final double filteredQuantity = filteredRecords.fold(
            0.0,
            (sum, r) => sum + r.quantity,
          );
          final double filteredLocalCostBasis = filteredRecords.fold(
            0.0,
            (sum, r) => sum + (r.quantity * r.purchasePrice),
          );

          final double filteredCostBasisBase =
              filteredLocalCostBasis * conversionFactor;
          final double filteredMarketValueBaseConverted =
              filteredQuantity *
              holding.currentPrice *
              marketValueConversionFactor;

          final double filteredProfitLoss =
              filteredMarketValueBaseConverted - filteredCostBasisBase;
          final double filteredProfitLossPercentage = filteredCostBasisBase > 0
              ? (filteredProfitLoss / filteredCostBasisBase) * 100
              : 0.0;

          final double filteredAvgPurchasePrice = filteredQuantity > 0
              ? filteredLocalCostBasis / filteredQuantity
              : 0.0;

          final double totalPortfolioValue = valuation.totalCurrentValue;
          final double filteredWeightPercentage = totalPortfolioValue > 0
              ? (filteredMarketValueBaseConverted / totalPortfolioValue) * 100
              : 0.0;

          final baseCurrencyCode =
              controller.selectedPortfolio.value?.currency ?? 'USD';
          final baseCurrencyFormatter = NumberFormat.currency(
            symbol: AppTheme.getCurrencySymbol(baseCurrencyCode),
            decimalDigits: 2,
          );

          final localCurrencySymbol = AppTheme.getCurrencySymbol(
            holding.currency,
          );
          final localCurrencyFormatter = NumberFormat.currency(
            symbol: localCurrencySymbol,
            decimalDigits: 2,
          );
          final percentFormatter = NumberFormat.decimalPercentPattern(
            decimalDigits: 2,
          );

          final isProfit = filteredProfitLoss >= 0;
          final gainLossColor = isProfit
              ? theme.successNormalColor
              : theme.errorNormalColor;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: 16,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Asset details card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.bgColorContainer,
                        borderRadius: BorderRadius.circular(
                          theme.radiusMap['medium'] ?? 8,
                        ),
                        border: Border.all(
                          color: gainLossColor.withValues(alpha: 0.25),
                          width: 1.5,
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Symbol + Long Name Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.brandNormalColor,
                                  borderRadius: BorderRadius.circular(
                                    theme.radiusMap['medium'] ?? 8,
                                  ),
                                ),
                                child: Text(
                                  holding.symbol,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      holding.name,
                                      style: TextStyle(
                                        color: theme.textColorPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Currency: ${holding.currency}',
                                      style: TextStyle(
                                        color: theme.textColorPlaceholder,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Valuation Return Percent Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: gainLossColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: gainLossColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${isProfit ? "+" : ""}${percentFormatter.format(filteredProfitLossPercentage / 100.0)}',
                                  style: TextStyle(
                                    color: gainLossColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Divider(color: theme.componentBorderColor, height: 1),
                          const SizedBox(height: 12),

                          // Broker Filter Dropdown Selection Block
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Custodian Filter:',
                                style: TextStyle(
                                  color: theme.textColorSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.bgColorSecondaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    theme.radiusMap['medium'] ?? 8,
                                  ),
                                  border: Border.all(
                                    color: theme.componentBorderColor,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedBrokerFilter.value,
                                    dropdownColor: theme.bgColorContainer,
                                    style: TextStyle(
                                      color: theme.textColorPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: theme.brandNormalColor,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'All',
                                        child: Text('All Brokers'),
                                      ),
                                      ...uniqueBrokers.map(
                                        (broker) => DropdownMenuItem(
                                          value: broker,
                                          child: Text(broker),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        selectedBrokerFilter.value = val;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Divider(color: theme.componentBorderColor, height: 1),
                          const SizedBox(height: 16),

                          // Responsive metric rows without fixed child aspect ratio
                          Builder(
                            builder: (context) {
                              final metrics = [
                                _buildMetricItem(
                                  context,
                                  'Market Value',
                                  baseCurrencyFormatter.format(
                                    filteredMarketValueBaseConverted,
                                  ),
                                  isBold: true,
                                ),
                                _buildMetricItem(
                                  context,
                                  'Total Cost Basis',
                                  baseCurrencyFormatter.format(
                                    filteredCostBasisBase,
                                  ),
                                ),
                                _buildMetricItem(
                                  context,
                                  'Total Return',
                                  '${isProfit ? "+" : ""}${baseCurrencyFormatter.format(filteredProfitLoss)}',
                                  color: gainLossColor,
                                ),
                                _buildMetricItem(
                                  context,
                                  'Shares Owned',
                                  filteredQuantity.toString(),
                                ),
                                _buildMetricItem(
                                  context,
                                  'Avg Purchase Price',
                                  localCurrencyFormatter.format(
                                    filteredAvgPurchasePrice,
                                  ),
                                ),
                                _buildMetricItem(
                                  context,
                                  'Current Price',
                                  localCurrencyFormatter.format(
                                    holding.currentPrice,
                                  ),
                                ),
                                _buildMetricItem(
                                  context,
                                  'Portfolio Weight',
                                  '${filteredWeightPercentage.toStringAsFixed(2)}%',
                                ),
                              ];

                              final columnsCount = isMobile ? 2 : 4;
                              List<Widget> rows = [];

                              for (
                                int i = 0;
                                i < metrics.length;
                                i += columnsCount
                              ) {
                                int end = i + columnsCount;
                                if (end > metrics.length) end = metrics.length;

                                final rowItems = metrics.sublist(i, end);

                                rows.add(
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: i + columnsCount < metrics.length
                                          ? 12
                                          : 0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ...rowItems.map(
                                          (item) => Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: item,
                                            ),
                                          ),
                                        ),
                                        // Spacer padding to keep column alignment aligned perfectly on the last row
                                        ...List.generate(
                                          columnsCount - rowItems.length,
                                          (_) =>
                                              const Expanded(child: SizedBox()),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: rows,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Trade/Purchase history list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction Trade History',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textColorPrimary,
                          ),
                        ),
                        Text(
                          '${filteredRecords.length} transactions',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (filteredRecords.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.bgColorContainer,
                          borderRadius: BorderRadius.circular(
                            theme.radiusMap['medium'] ?? 8,
                          ),
                          border: Border.all(color: theme.componentBorderColor),
                        ),
                        child: Center(
                          child: Text(
                            'No purchase history found for the selected filter.',
                            style: TextStyle(
                              color: theme.textColorSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          final formattedDate = DateFormat('yyyy-MM-dd').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              record.purchaseDate,
                            ),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.bgColorContainer,
                              borderRadius: BorderRadius.circular(
                                theme.radiusMap['medium'] ?? 8,
                              ),
                              border: Border.all(
                                color: theme.componentBorderColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Date & Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.brandLightColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: theme.brandNormalColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: theme.textColorPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 2,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          TDTag(
                                            record.broker,
                                            size: TDTagSize.small,
                                            theme: TDTagTheme.defaultTheme,
                                            shape: TDTagShape.round,
                                          ),
                                          Text(
                                            '${record.quantity} shares @ ${localCurrencyFormatter.format(record.purchasePrice)}',
                                            style: TextStyle(
                                              color: theme.textColorSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Total Cost Column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      localCurrencyFormatter.format(
                                        record.quantity * record.purchasePrice,
                                      ),
                                      style: TextStyle(
                                        color: theme.textColorPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Total Cost',
                                      style: TextStyle(
                                        color: theme.textColorPlaceholder,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 20,
                                  child: VerticalDivider(
                                    color: theme.componentBorderColor,
                                    width: 1,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Actions
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: theme.textColorSecondary,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        final recordAsHolding = HoldingValuation(
                                          id: record.id,
                                          symbol: record.symbol,
                                          name: record.name,
                                          quantity: record.quantity,
                                          purchaseDate: record.purchaseDate,
                                          purchasePrice: record.purchasePrice,
                                          currentPrice: holding.currentPrice,
                                          costBasis:
                                              record.quantity *
                                              record.purchasePrice,
                                          currentValue:
                                              record.quantity *
                                              holding.currentPrice,
                                          profitLoss:
                                              (holding.currentPrice -
                                                  record.purchasePrice) *
                                              record.quantity,
                                          profitLossPercentage:
                                              record.purchasePrice > 0
                                              ? ((holding.currentPrice -
                                                            record
                                                                .purchasePrice) /
                                                        record.purchasePrice) *
                                                    100
                                              : 0,
                                          currency: holding.currency,
                                          previousClose: holding.previousClose,
                                          weightPercentage: 0,
                                          broker: record.broker,
                                        );

                                        Get.to(
                                          () => AddAssetDialog(
                                            editHolding: recordAsHolding,
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: theme.errorNormalColor,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => TDAlertDialog(
                                            title: 'Delete Record',
                                            content:
                                                'Are you sure you want to delete this purchase record of ${record.quantity} ${record.symbol} shares?',
                                            backgroundColor:
                                                theme.bgColorContainer,
                                            leftBtn: TDDialogButtonOptions(
                                              title: 'Cancel',
                                              action: () =>
                                                  Navigator.pop(context),
                                            ),
                                            rightBtn: TDDialogButtonOptions(
                                              title: 'Delete',
                                              theme: TDButtonTheme.danger,
                                              action: () async {
                                                Navigator.pop(context);
                                                final success = await controller
                                                    .deleteAssetHolding(
                                                      record.id,
                                                    );
                                                if (success) {
                                                  Get.snackbar(
                                                    'Success',
                                                    'Purchase record deleted.',
                                                    snackPosition:
                                                        SnackPosition.BOTTOM,
                                                    backgroundColor: theme
                                                        .successNormalColor,
                                                    colorText: Colors.white,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    final theme = TDTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.textColorSecondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color ?? theme.textColorPrimary,
              fontWeight: isBold || color != null
                  ? FontWeight.bold
                  : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
