class PortfolioValuation {
  final String portfolioId;
  final String currency;
  final double totalCostBasis;
  final double totalCurrentValue;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;
  final List<HoldingValuation> holdings;

  PortfolioValuation({
    required this.portfolioId,
    required this.currency,
    required this.totalCostBasis,
    required this.totalCurrentValue,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.holdings,
  });

  factory PortfolioValuation.empty(String portfolioId) {
    return PortfolioValuation(
      portfolioId: portfolioId,
      currency: 'USD',
      totalCostBasis: 0.0,
      totalCurrentValue: 0.0,
      totalProfitLoss: 0.0,
      totalProfitLossPercentage: 0.0,
      holdings: [],
    );
  }

  factory PortfolioValuation.fromJson(Map<String, dynamic> json) {
    var holdingsList = json['holdings'] as List? ?? [];
    List<HoldingValuation> parsedHoldings = holdingsList
        .map((h) => HoldingValuation.fromJson(h as Map<String, dynamic>))
        .toList();

    return PortfolioValuation(
      portfolioId: json['portfolioId'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      totalCostBasis: (json['totalCostBasis'] as num?)?.toDouble() ?? 0.0,
      totalCurrentValue: (json['totalCurrentValue'] as num?)?.toDouble() ?? 0.0,
      totalProfitLoss: (json['totalProfitLoss'] as num?)?.toDouble() ?? 0.0,
      totalProfitLossPercentage: (json['totalProfitLossPercentage'] as num?)?.toDouble() ?? 0.0,
      holdings: parsedHoldings,
    );
  }
}

class HoldingValuation {
  final String id;
  final String symbol;
  final String name;
  final double quantity;
  final int purchaseDate;
  final double purchasePrice;
  final double currentPrice;
  final double costBasis;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercentage;
  final String currency;
  final double previousClose;
  final double weightPercentage;
  final String broker;

  HoldingValuation({
    required this.id,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.currentPrice,
    required this.costBasis,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercentage,
    required this.currency,
    required this.previousClose,
    required this.weightPercentage,
    required this.broker,
  });

  factory HoldingValuation.fromJson(Map<String, dynamic> json) {
    return HoldingValuation(
      id: json['id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchaseDate'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      costBasis: (json['costBasis'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      profitLoss: (json['profitLoss'] as num?)?.toDouble() ?? 0.0,
      profitLossPercentage: (json['profitLossPercentage'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      previousClose: (json['previousClose'] as num?)?.toDouble() ?? 0.0,
      weightPercentage: (json['weightPercentage'] as num?)?.toDouble() ?? 0.0,
      broker: json['broker'] as String? ?? 'Other',
    );
  }
}
