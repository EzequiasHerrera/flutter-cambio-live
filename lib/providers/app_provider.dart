import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../models/cart_item.dart';
import '../services/currency_service.dart';

class AppProvider with ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();

  Currency? _baseCurrency;
  Currency? _targetCurrency;
  Map<String, double> _rates = {};
  final List<CartItem> _cart = [];

  Currency? get baseCurrency => _baseCurrency;
  Currency? get targetCurrency => _targetCurrency;
  List<CartItem> get cart => _cart;
  double get totalSaved => _cart.fold(0, (sum, item) => sum + item.targetAmount);

  // Initial list of available currencies
  final List<Currency> availableCurrencies = [
    Currency(code: 'USD', name: 'US Dollar', rate: 1.0),
    Currency(code: 'EUR', name: 'Euro', rate: 1.0),
    Currency(code: 'BRL', name: 'Real Brasileiro', rate: 1.0),
    Currency(code: 'ARS', name: 'Peso Argentino', rate: 1.0),
    Currency(code: 'GBP', name: 'British Pound', rate: 1.0),
    Currency(code: 'JPY', name: 'Japanese Yen', rate: 1.0),
  ];

  AppProvider() {
    _baseCurrency = availableCurrencies.firstWhere((c) => c.code == 'USD');
    _targetCurrency = availableCurrencies.firstWhere((c) => c.code == 'ARS');
    fetchRates();
  }

  void setBaseCurrency(Currency currency) {
    _baseCurrency = currency;
    fetchRates();
    notifyListeners();
  }

  void setTargetCurrency(Currency currency) {
    _targetCurrency = currency;
    notifyListeners();
  }

  Future<void> fetchRates() async {
    if (_baseCurrency == null) return;
    _rates = await _currencyService.fetchRates(_baseCurrency!.code);
    notifyListeners();
  }

  double convert(double amount) {
    if (_targetCurrency == null || _rates.isEmpty) return 0.0;
    // Rate from API is usually 1 Base -> N Target
    double rate = _rates[_targetCurrency!.code] ?? 1.0;
    return amount * rate;
  }

  void addToCart(double original, double converted) {
    if (_baseCurrency == null || _targetCurrency == null) return;
    _cart.add(CartItem(
      originalAmount: original,
      originalCurrency: _baseCurrency!,
      targetAmount: converted,
      targetCurrency: _targetCurrency!,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
