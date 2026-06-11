import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';

  /// Fetches exchange rates for the given [baseCode].
  /// Returns a map of currency codes to their exchange rates.
  Future<Map<String, double>> fetchRates(String baseCode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$baseCode'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
          data['rates'].map((key, value) => MapEntry(key, (value as num).toDouble())),
        );
        return rates;
      } else {
        debugPrint('Failed to fetch rates: ${response.statusCode}');
        return _getMockRates(baseCode);
      }
    } catch (e) {
      debugPrint('Error fetching rates: $e');
      return _getMockRates(baseCode);
    }
  }

  /// Provides fallback rates in case the API call fails or for offline development.
  Map<String, double> _getMockRates(String baseCode) {
    if (baseCode == 'USD') {
      return {'USD': 1.0, 'EUR': 0.85, 'BRL': 5.0, 'GBP': 0.75, 'JPY': 110.0, 'ARS': 850.0};
    }
    return {'USD': 1.0, 'EUR': 0.85, 'BRL': 5.0, 'ARS': 850.0};
  }
}

