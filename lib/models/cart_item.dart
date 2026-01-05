import 'currency.dart';

class CartItem {
  final double originalAmount;
  final Currency originalCurrency;
  final double targetAmount;
  final Currency targetCurrency;
  final DateTime timestamp;

  CartItem({
    required this.originalAmount,
    required this.originalCurrency,
    required this.targetAmount,
    required this.targetCurrency,
    required this.timestamp,
  });
}
