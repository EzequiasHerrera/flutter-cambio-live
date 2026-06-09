class Currency {
  final String code;
  final String name;
  final String symbol;

  const Currency({
    required this.code,
    required this.name,
    this.symbol = '',
  });

  /// Returns the two-letter country code for flags, with special cases.
  String get flagCode {
    if (code == 'EUR') return 'EU';
    if (code == 'CUSTOM') return 'CUSTOM';
    return code.length >= 2 ? code.substring(0, 2) : code;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Currency(code: $code, name: $name)';
}
