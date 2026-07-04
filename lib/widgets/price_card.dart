import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/widgets/action_button.dart';
import 'package:howmuch/widgets/currency_icon.dart';
import 'package:howmuch/theme/app_theme.dart';

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
    final provider = Provider.of<AppProvider>(context);

    // Forzamos el uso de los colores y estilo del tema claro (Light Theme)
    final lightTheme = AppTheme.lightTheme;
    final colorScheme = lightTheme.colorScheme;

    // Colores de gris específicos para legibilidad en modo claro
    final secondaryTextColor = Colors.grey[600];
    final mainTextColor = Colors.grey[800];

    return Theme(
      data: lightTheme,
      child: Card(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 14, color: secondaryTextColor),
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
                        style: TextStyle(
                          color: secondaryTextColor,
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
                      Text(
                        'Precio Original',
                        style: TextStyle(
                          color: secondaryTextColor?.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${provider.baseCurrency?.code} $text',
                        style: TextStyle(
                          color: mainTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(
                color: mainTextColor?.withOpacity(0.1),
                height: 25,
              ),
              // Precio convertido
              Text(
                '${provider.targetCurrency?.symbol ?? currencyCode} ${formatPrice(convertedValue)}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              Theme(
                data: AppTheme.darkTheme,
                child: ActionButton(
                  icon: Icons.add_shopping_cart,
                  label: "Guardar Precio",
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatPrice(double price) {
  final String s = price.toStringAsFixed(2).replaceAll('.', ',');
  return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
}