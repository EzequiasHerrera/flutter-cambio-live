class Currency {
  final String code; // USD, EUR, BRL
  final String name; // United States Dollar
  final double rate; // Exchange rate relative to base

  Currency({
    required this.code,
    required this.name,
    required this.rate,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'],
      name: json['name'] ?? '',
      rate: (json['rate'] as num).toDouble(),
    );
  }
}
