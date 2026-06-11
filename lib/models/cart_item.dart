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

  /// Factory constructor for creating a CartItem from JSON (if needed later)
  // factory CartItem.fromJson(Map<String, dynamic> json) => ...

  @override
  String toString() {
    return 'CartItem(original: $originalAmount ${originalCurrency.code}, target: $targetAmount ${targetCurrency.code})';
  }
}
