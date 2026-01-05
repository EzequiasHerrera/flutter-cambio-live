import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/currency.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambio Live'),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.availableCurrencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Seleccione las Monedas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                // Base Currency
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text('Desde (Cámara):', style: TextStyle(fontSize: 16)),
                    ),
                    Expanded(
                      flex: 3,
                      child: DropdownButton<Currency>(
                        isExpanded: true,
                        value: provider.baseCurrency,
                        items: provider.availableCurrencies.map((Currency currency) {
                          return DropdownMenuItem<Currency>(
                            value: currency,
                            child: Text('${currency.code} - ${currency.name}'),
                          );
                        }).toList(),
                        onChanged: (Currency? newValue) {
                          if (newValue != null) {
                            provider.setBaseCurrency(newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Target Currency
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text('Hacia (Ver):', style: TextStyle(fontSize: 16)),
                    ),
                    Expanded(
                      flex: 3,
                      child: DropdownButton<Currency>(
                        isExpanded: true,
                        value: provider.targetCurrency,
                        items: provider.availableCurrencies.map((Currency currency) {
                          return DropdownMenuItem<Currency>(
                            value: currency,
                            child: Text('${currency.code} - ${currency.name}'),
                          );
                        }).toList(),
                        onChanged: (Currency? newValue) {
                          if (newValue != null) {
                            provider.setTargetCurrency(newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                // Button to Camera
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ir a la Cámara', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/camera');
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Button to Cart
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Ver Carrito', style: TextStyle(fontSize: 18)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
