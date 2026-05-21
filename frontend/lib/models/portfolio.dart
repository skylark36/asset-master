class Portfolio {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String currency;
  final int createdAt;

  Portfolio({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.currency,
    required this.createdAt,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Portfolio',
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      createdAt: json['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'currency': currency,
      'created_at': createdAt,
    };
  }
}
