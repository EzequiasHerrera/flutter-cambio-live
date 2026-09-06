class Currency {
  final String code;
  final String name;
  final String symbol;
  final bool isCustom;

  const Currency({
    required this.code,
    required this.name,
    this.symbol = '',
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'isCustom': isCustom,
      };

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'],
        name: json['name'],
        symbol: json['symbol'] ?? '',
        isCustom: json['isCustom'] ?? false,
      );

  /// Returns the two-letter country code for flags, with special cases.
  String get flagCode {
    if (isCustom) return 'CUSTOM';
    if (code == 'EUR') return 'EU';
    return code.length >= 2 ? code.substring(0, 2) : code;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Currency(code: $code, name: $name, isCustom: $isCustom)';
}
