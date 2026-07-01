import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Apunta a tu Worker
  static const String _proxyUrl =
      'https://howmuch-api-proxy.ezequiasherrera99.workers.dev';

  // Guardamos los rates en memoria para no llamar al proxy a cada rato
  Map<String, double>? _cachedRates;

  Future<Map<String, double>> fetchRates(String baseCode) async {
    try {
      if (_cachedRates == null) {
        // Llamamos al proxy para obtener las tasas y lo parseamos a JSON
        final response = await http.get(Uri.parse(_proxyUrl));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // El JSON tiene la estructura: "rates": {"USD": 1.0, "ARS": 1483.02, ...}
          _cachedRates = Map<String, double>.from(
            (data['rates'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                (value as num).toDouble(),
              ),
            ),
          );
        }
      }

      // Si tenemos rates (sea por cache o recién cargados), los ajustamos a la base solicitada
      if (_cachedRates != null) {
        final double baseRate = _cachedRates![baseCode] ?? 1.0;
        return _cachedRates!.map(
          (key, value) => MapEntry(key, value / baseRate),
        );
      }

      return _getMockRates(baseCode);
    } catch (e) {
      debugPrint('Error fetching rates from proxy: $e');
      return _getMockRates(baseCode);
    }
  }

  // Mock de tasas para pruebas
  Map<String, double> _getMockRates(String baseCode) {
    final mockRates = {'USD': 1.0, 'EUR': 0.87, 'BRL': 5.18, 'ARS': 1483.02};
    final baseRate = mockRates[baseCode] ?? 1.0;
    return mockRates.map((key, value) => MapEntry(key, value / baseRate));
  }
}
