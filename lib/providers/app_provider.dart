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

  // Getters
  Currency? get baseCurrency => _baseCurrency;
  Currency? get targetCurrency => _targetCurrency;
  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  bool get useCustomCurrency => _useCustomCurrency;
  String get customName => _customName;
  double get customRate => _customRate;

  // Lista de monedas disponibles (Sin el parámetro 'rate' que ensucia el modelo)
  final List<Currency> availableCurrencies = [
    Currency(code: 'USD', name: 'US Dollar'),
    Currency(code: 'EUR', name: 'Euro'),
    Currency(code: 'BRL', name: 'Real Brasileiro'),
    Currency(code: 'ARS', name: 'Peso Argentino'),
    Currency(code: 'GBP', name: 'British Pound'),
    Currency(code: 'JPY', name: 'Japanese Yen'),
  ];

  AppProvider() {
    // Inicialización por defecto
    _baseCurrency = availableCurrencies.firstWhere((c) => c.code == 'USD');
    _targetCurrency = availableCurrencies.firstWhere((c) => c.code == 'ARS');
    fetchRates();
  }

  // Lógica de cálculo del total en el carrito
  double get totalSaved {
    if (_targetCurrency == null || (_rates.isEmpty && !_useCustomCurrency)) return 0.0;

    double total = 0.0;
    for (var item in _cart) {
      if (_useCustomCurrency) {
        total += item.originalAmount * _customRate;
      } else {
        // Obtenemos la tasa de la moneda del item respecto a la base actual
        double rateToTarget = _rates[_targetCurrency!.code] ?? 1.0;
        double rateToOriginal = _rates[item.originalCurrency.code] ?? 1.0;

        if (item.originalCurrency.code == _baseCurrency?.code) {
          total += convert(item.originalAmount);
        } else {
          // Ajuste de tasas cruzadas
          total += item.originalAmount * (rateToTarget / rateToOriginal);
        }
      }
    }
    return total;
  }

  // CAMBIAR MONEDA BASE
  void setBaseCurrency(Currency currency) {
    _baseCurrency = currency;
    // Si no estamos en modo personalizado, actualizamos tasas desde la API
    if (!_useCustomCurrency) fetchRates();
    notifyListeners();
  }

  // CAMBIAR MONEDA DESTINO (De la lista oficial)
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
    // IMPORTANTE: El código 'CUSTOM' activa el icono especial en la UI
    _targetCurrency = Currency(code: 'CUSTOM', name: name);
    notifyListeners();
  }

  // INTERCAMBIAR MONEDAS
  void swapCurrencies() {
    if (_useCustomCurrency) return; // No se puede swap si una es manual
    if (_baseCurrency == null || _targetCurrency == null) return;

    final temp = _baseCurrency;
    _baseCurrency = _targetCurrency;
    _targetCurrency = temp;

    fetchRates();
    notifyListeners();
  }

  // OBTENER TASAS DESDE EL SERVICIO
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

  // CONVERTIR MONTO
  double convert(double amount) {
    if (_useCustomCurrency) {
      return amount * _customRate;
    }
    if (_targetCurrency == null || _rates.isEmpty) return 0.0;

    double rate = _rates[_targetCurrency!.code] ?? 1.0;
    return amount * rate;
  }

  // AGREGAR AL CARRITO
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

  // LIMPIAR CARRITO
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}