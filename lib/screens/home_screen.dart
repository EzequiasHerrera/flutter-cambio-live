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
        title: Image.asset(
          'assets/images/logo.png', // Ruta del logo
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            // Si la imagen no existe todavía, muestra el texto original como respaldo
            return const Text('Cambio Live', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue));
          },
        ),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.availableCurrencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Cálculo de la tasa unitaria para mostrar en el menú
          final double unitRate = provider.convert(1.0);
          final String baseCode = provider.baseCurrency?.code ?? '';
          final String targetCode = provider.targetCurrency?.code ?? '';

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
                const SizedBox(height: 30),
                // Tasa de cambio informativa
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '1 $baseCode = ${unitRate.toStringAsFixed(2)} $targetCode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Button to Camera
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ir a la Cámara', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/camera');
                    },
                  ),
                ),
                const SizedBox(height: 15),
                // Button to Cart
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Ver Carrito', style: TextStyle(fontSize: 18)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
