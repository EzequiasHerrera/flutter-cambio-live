import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency.dart';

class CurrencyService {
  final String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';

  Future<Map<String, double>> fetchRates(String baseCode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$baseCode'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(data['rates'].map((key, value) => MapEntry(key, (value as num).toDouble())));
        return rates;
      } else {
        // Fallback for demo if API fails
        return _getMockRates(baseCode);
      }
    } catch (e) {
      print('Error fetching rates: $e');
      return _getMockRates(baseCode);
    }
  }

  Map<String, double> _getMockRates(String baseCode) {
    if (baseCode == 'USD') {
      return {'USD': 1.0, 'EUR': 0.85, 'BRL': 5.0, 'GBP': 0.75, 'JPY': 110.0};
    }
    return {'USD': 1.0, 'EUR': 0.85, 'BRL': 5.0}; // Simplified
  }
}
