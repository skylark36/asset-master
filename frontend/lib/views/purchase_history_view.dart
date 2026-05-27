import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import '../theme/app_theme.dart'; // Still keep for helper methods like getCurrencySymbol if needed

class PurchaseHistoryView extends StatefulWidget {
  const PurchaseHistoryView({super.key});

  @override
  State<PurchaseHistoryView> createState() => _PurchaseHistoryViewState();
}

class _PurchaseHistoryViewState extends State<PurchaseHistoryView> {
  final controller = Get.find<PortfolioController>();
  late final TextEditingController _searchTextController;

  @override
  void initState() {
    super.initState();
    _searchTextController = TextEditingController(
      text: controller.purchaseHistorySearchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    String formatDate(int timestamp) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: theme.bgColorPage,
      appBar: AppBar(
        backgroundColor: theme.bgColorContainer,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.textColorPrimary,
            size: 16,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Purchase History',
          style: TextStyle(
            color: theme.textColorPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.componentBorderColor, height: 1),
        ),
      ),
      body: Obx(() {
        final assets = controller.assets;

        final searchQuery = controller.purchaseHistorySearchQuery.value
            .toLowerCase()
            .trim();
        final filteredAssets = assets.where((asset) {
          return asset.symbol.toLowerCase().contains(searchQuery) ||
              asset.name.toLowerCase().contains(searchQuery) ||
              asset.broker.toLowerCase().contains(searchQuery);
        }).toList();

        // Sort by purchaseDate descending (newest first)
        filteredAssets.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

        String getAssetCurrency(String symbol) {
          final holding = controller.valuation.value?.holdings.firstWhereOrNull(
            (h) => h.symbol.toLowerCase() == symbol.toLowerCase(),
          );
          return holding?.currency ??
              controller.selectedPortfolio.value?.currency ??
              'USD';
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 700;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: isMobile ? 80 : 16,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar
                  TDInput(
                    controller: _searchTextController,
                    onChanged: (value) =>
                        controller.purchaseHistorySearchQuery.value = value,
                    hintText: 'Search by ticker, name, or broker...',
                    leftIcon: Icon(
                      Icons.search_rounded,
                      color: theme.textColorSecondary,
                      size: 16,
                    ),
                    textStyle: TextStyle(
                      color: theme.textColorPrimary,
                      fontSize: 12,
                    ),
                    hintTextStyle: TextStyle(
                      color: theme.textColorPlaceholder,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.transparent,
                    showBottomDivider: true,
                    needClear: true,
                    onClearTap: () {
                      _searchTextController.clear();
                      controller.purchaseHistorySearchQuery.value = '';
                    },
                  ),
                  const SizedBox(height: 16),

                  // List
                  if (filteredAssets.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: theme.bgColorContainer,
                        borderRadius: BorderRadius.circular(
                          theme.radiusMap['medium'] ?? 8,
                        ),
                        border: Border.all(color: theme.componentBorderColor),
                      ),
                      child: Center(
                        child: Text(
                          'No matching purchase records found.',
                          style: TextStyle(
                            color: theme.textColorSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredAssets.length,
                        separatorBuilder: (context, index) => Divider(
                          color: theme.componentBorderColor,
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final asset = filteredAssets[index];
                          final dateStr = formatDate(asset.purchaseDate);
                          final totalCost =
                              asset.quantity * asset.purchasePrice;
                          final currencyCode = getAssetCurrency(asset.symbol);
                          final currencySym = AppTheme.getCurrencySymbol(
                            currencyCode,
                          );

                          return Row(
                            children: [
                              // Ticker Symbol Badge
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.brandLightColor,
                                  borderRadius: BorderRadius.circular(
                                    theme.radiusMap['medium'] ?? 8,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    asset.symbol,
                                    style: TextStyle(
                                      color: theme.brandNormalColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      asset.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.textColorPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${asset.quantity.toStringAsFixed(2)} shares @ $currencySym${asset.purchasePrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: theme.textColorSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          asset.broker,
                                          style: TextStyle(
                                            color: theme.brandNormalColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: theme.textColorPlaceholder,
                                            fontSize: 9,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: theme.textColorPlaceholder,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$currencySym${totalCost.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: theme.textColorPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total Cost',
                                    style: TextStyle(
                                      color: theme.textColorSecondary,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
