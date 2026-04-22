import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/action_button.dart';
import '../widgets/currency_icon.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<AppProvider>(context);

    return Card(
      color: colorScheme.tertiaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Izquierda: banderas y par de conversión
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CurrencyIcon(
                          currencyCode: provider.baseCurrency?.code ?? '',
                          width: 24,
                          height: 16,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 14, color: Colors.black45),
                        ),
                        CurrencyIcon(
                          currencyCode: provider.targetCurrency?.code ?? '',
                          width: 24,
                          height: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.baseCurrency?.code} → ${provider.targetCurrency?.code}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Derecha: precio original
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Precio Original',
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    Text(
                      '${provider.baseCurrency?.code} $text',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.black12, height: 25),
            // Precio convertido
            Text(
              '$currencyCode ${convertedValue.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF8C4404),
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ActionButton(
              icon: Icons.add_shopping_cart,
              label: "Guardar Precio",
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}