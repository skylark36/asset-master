class Asset {
  final String id;
  final String portfolioId;
  final String symbol;
  final String name;
  final double quantity;
  final double purchasePrice;
  final int purchaseDate;
  final String broker;

  Asset({
    required this.id,
    required this.portfolioId,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.broker,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String? ?? '',
      portfolioId: json['portfolio_id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchase_date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      broker: json['broker'] as String? ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolio_id': portfolioId,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate,
      'broker': broker,
    };
  }
}
