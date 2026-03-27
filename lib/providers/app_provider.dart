import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../models/cart_item.dart';
import '../services/currency_service.dart';

class AppProvider with ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();

  Currency? _baseCurrency;
  Currency? _targetCurrency;
  Map<String, double> _rates = {};
  bool _isLoading = false;
  final List<CartItem> _cart = [];

  // MONEDA PERSONALIZADA
  bool _useCustomCurrency = false;
  String _customName = "Personalizada";
  double _customRate = 1.0;

  Currency? get baseCurrency => _baseCurrency;
  Currency? get targetCurrency => _targetCurrency;
  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  bool get useCustomCurrency => _useCustomCurrency;
  String get customName => _customName;
  double get customRate => _customRate;

  double get totalSaved {
    if (_targetCurrency == null || (_rates.isEmpty && !_useCustomCurrency)) return 0.0;
    
    double total = 0.0;
    for (var item in _cart) {
      if (_useCustomCurrency) {
        total += item.originalAmount * _customRate;
      } else {
        double rateToTarget = _rates[_targetCurrency!.code] ?? 1.0;
        double rateToOriginal = _rates[item.originalCurrency.code] ?? 1.0;
        
        if (item.originalCurrency.code == _baseCurrency?.code) {
          total += convert(item.originalAmount);
        } else {
          total += item.originalAmount * (rateToTarget / rateToOriginal);
        }
      }
    }
    return total;
  }

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
    if (!_useCustomCurrency) fetchRates();
    notifyListeners();
  }

  void setTargetCurrency(Currency currency) {
    _useCustomCurrency = false;
    _targetCurrency = currency;
    fetchRates();
    notifyListeners();
  }

  // CONFIGURAR MONEDA PERSONALIZADA
  void setCustomCurrency(String name, double rate) {
    _customName = name;
    _customRate = rate;
    _useCustomCurrency = true;
    _targetCurrency = Currency(code: 'CUSTOM', name: name, rate: rate);
    notifyListeners();
  }

  void swapCurrencies() {
    if (_useCustomCurrency) return; // No se puede enrocar si es personalizada
    if (_baseCurrency == null || _targetCurrency == null) return;
    final temp = _baseCurrency;
    _baseCurrency = _targetCurrency;
    _targetCurrency = temp;
    fetchRates();
    notifyListeners();
  }

  Future<void> fetchRates() async {
    if (_baseCurrency == null || _useCustomCurrency) return;
    _isLoading = true;
    notifyListeners();
    _rates = await _currencyService.fetchRates(_baseCurrency!.code);
    _isLoading = false;
    notifyListeners();
  }

  double convert(double amount) {
    if (_useCustomCurrency) {
      return amount * _customRate;
    }
    if (_targetCurrency == null || _rates.isEmpty) return 0.0;
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
