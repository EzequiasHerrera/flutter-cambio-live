import 'package:howmuch/models/currency.dart';

class CartItem {
  final double originalAmount;
  final Currency originalCurrency;
  final double targetAmount;
  final Currency targetCurrency;
  final DateTime timestamp;

  const CartItem({
    required this.originalAmount,
    required this.originalCurrency,
    required this.targetAmount,
    required this.targetCurrency,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'originalAmount': originalAmount,
        'originalCurrency': originalCurrency.toJson(),
        'targetAmount': targetAmount,
        'targetCurrency': targetCurrency.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        originalAmount: json['originalAmount'],
        originalCurrency: Currency.fromJson(json['originalCurrency']),
        targetAmount: json['targetAmount'],
        targetCurrency: Currency.fromJson(json['targetCurrency']),
        timestamp: DateTime.parse(json['timestamp']),
      );

  /// Factory constructor for creating a CartItem from JSON (if needed later)
  // factory CartItem.fromJson(Map<String, dynamic> json) => ...

  @override
  String toString() {
    return 'CartItem(original: $originalAmount ${originalCurrency.code}, target: $targetAmount ${targetCurrency.code})';
  }
}
