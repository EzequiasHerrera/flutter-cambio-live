import 'package:flutter/material.dart';
import 'package:howmuch/services/storage_service.dart';
import '../models/currency.dart';
import '../models/cart_item.dart';
import '../services/currency_service.dart';

class AppProvider with ChangeNotifier {
  // Service Currencies from API
  final CurrencyService _currencyService = CurrencyService();

  // Service: Local Storage
  final StorageService _storage = StorageService();

  // State: Currencies
  Currency? _baseCurrency;
  Currency? _targetCurrency;
  Map<String, double> _rates = {};
  bool _isLoading = false;

  // State: Custom Currency
  bool _useCustomCurrency = false;
  String _customName = "Personalizada";
  double _customRate = 1.0;

  // State: Cart
  final List<CartItem> _cart = [];

  // Data: Available Currencies
  final List<Currency> availableCurrencies = [
    Currency(code: 'USD', name: 'US Dollar', symbol: r'$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'BRL', name: 'Real Brasileiro', symbol: r'R$'),
    Currency(code: 'ARS', name: 'Peso Argentino', symbol: r'$'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  ];

  // Constructor
  AppProvider() {
    _initSettings();
    fetchRates();
  }

  Future<void> _initSettings() async {
    final settings = await _storage.getSettings();

    if (settings != null) {
      // 1. Restaurar estados básicos
      _useCustomCurrency = settings['useCustom'] ?? false;
      _customName = settings['customName'] ?? "Personalizada";
      _customRate = settings['customRate'] ?? 1.0;

      // 2. Restaurar moneda base
      final baseCode = settings['baseCode'];
      if (baseCode != null) {
        _baseCurrency = availableCurrencies.firstWhere(
          (c) => c.code == baseCode,
          orElse: () => availableCurrencies.first,
        );
      }

      // 3. Restaurar moneda destino (Lógica condicional)
      if (_useCustomCurrency) {
        // Si era personalizada, reconstruimos el objeto Currency especial
        _targetCurrency = Currency(
          code: 'CUSTOM',
          name: _customName,
          symbol: '',
        );
      } else {
        // Si era normal, buscamos en la lista
        final targetCode = settings['targetCode'];
        if (targetCode != null) {
          _targetCurrency = availableCurrencies.firstWhere(
            (c) => c.code == targetCode,
            orElse: () => availableCurrencies.last,
          );
        }
      }

      notifyListeners();
      // Opcional: si ya teníamos moneda base, volvemos a traer las tasas del día
      if (_baseCurrency != null) fetchRates();
    }
  }

  // Getters
  Currency? get baseCurrency => _baseCurrency;

  Currency? get targetCurrency => _targetCurrency;

  List<CartItem> get cart => _cart;

  bool get isLoading => _isLoading;

  bool get useCustomCurrency => _useCustomCurrency;

  String get customName => _customName;

  double get customRate => _customRate;

  // Logic: Calculations
  double get totalSaved {
    if (_targetCurrency == null || (_rates.isEmpty && !_useCustomCurrency))
      return 0.0;

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

  // Public Methods: Currency Management
  void setBaseCurrency(Currency currency) async {
    _baseCurrency = currency;
    if (!_useCustomCurrency) fetchRates();
    await _saveEverything();
    notifyListeners();
  }

  void setTargetCurrency(Currency currency) async {
    _useCustomCurrency = false;
    _targetCurrency = currency;
    fetchRates();
    await _saveEverything();
    notifyListeners();
  }

  void setCustomCurrency(String name, double rate) async {
    _customName = name;
    _customRate = rate;
    _useCustomCurrency = true;
    _targetCurrency = Currency(code: 'CUSTOM', name: name, symbol: '');
    await _saveEverything();
    notifyListeners();
  }

  Future<void> _saveEverything() async {
    final settings = {
      'baseCode': _baseCurrency?.code,
      'targetCode': _targetCurrency?.code,
      'useCustom': _useCustomCurrency,
      'customName': _customName,
      'customRate': _customRate,
    };
    await _storage.saveSettings(settings);
  }

  void disableCustomCurrency() {
    _useCustomCurrency = false;
    _targetCurrency = availableCurrencies.firstWhere(
      (c) => c.code != _baseCurrency?.code,
      orElse: () => availableCurrencies.first,
    );
    fetchRates();
    notifyListeners();
  }

  void swapCurrencies() async {
    if (_useCustomCurrency) return;
    if (_baseCurrency == null || _targetCurrency == null) return;

    final temp = _baseCurrency;
    _baseCurrency = _targetCurrency;
    _targetCurrency = temp;

    fetchRates();
    await _saveEverything();
    notifyListeners();
  }

  // Public Methods: Rates
  Future<void> fetchRates() async {
    if (_baseCurrency == null || _useCustomCurrency) return;

    _isLoading = true;
    notifyListeners();

    try {
      _rates = await _currencyService.fetchRates(_baseCurrency!.code);
    } catch (e) {
      debugPrint("Error al obtener tasas: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double convert(double amount) {
    if (_useCustomCurrency) {
      return amount * _customRate;
    }
    if (_targetCurrency == null || _rates.isEmpty) return 0.0;

    double rate = _rates[_targetCurrency!.code] ?? 1.0;
    return amount * rate;
  }

  // Public Methods: Cart Management
  void addToCart(double original, double converted) {
    if (_baseCurrency == null || _targetCurrency == null) return;

    _cart.add(
      CartItem(
        originalAmount: original,
        originalCurrency: _baseCurrency!,
        targetAmount: converted,
        targetCurrency: _targetCurrency!,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
