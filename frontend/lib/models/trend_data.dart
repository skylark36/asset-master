class TrendDataPoint {
  final String date;
  final double value;

  TrendDataPoint({
    required this.date,
    required this.value,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: json['date'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'value': value,
    };
  }
}
