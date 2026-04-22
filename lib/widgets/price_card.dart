import 'package:flutter/material.dart';

class PriceCard extends StatelessWidget {
  final String text;
  final double convertedValue;
  final String currencyCode;
  final VoidCallback onSave;

  const PriceCard({
    super.key,
    required this.text,
    required this.convertedValue,
    required this.currencyCode,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DETECTADO: $text',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '$currencyCode ${convertedValue.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('GUARDAR PRECIO'),
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}
