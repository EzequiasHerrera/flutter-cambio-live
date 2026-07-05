import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:provider/provider.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/widgets/action_button.dart';
import 'package:howmuch/widgets/currency_icon.dart';
import 'package:howmuch/theme/app_theme.dart';
import 'package:howmuch/services/feedback_service.dart';

class PriceCard extends StatefulWidget {
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
  State<PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends State<PriceCard> {
  @override
  void didUpdateWidget(PriceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disparar vibración y log solo cuando el valor cambia realmente
    if (oldWidget.convertedValue != widget.convertedValue) {
      FeedbackService.heavy();
      dev.log("Precio actualizado: ${widget.convertedValue}", name: "PRICE_CARD");
    }
  }

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
                        '${provider.baseCurrency?.code} ${widget.text}',
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
                height: 12,
              ),
              // Precio convertido con animación de escala
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                reverseDuration: const Duration(milliseconds: 0),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '${provider.targetCurrency?.symbol ?? widget.currencyCode} ${formatPrice(widget.convertedValue)}',
                  // La ValueKey asegura que AnimatedSwitcher detecte el cambio y dispare la animación
                  key: ValueKey<double>(widget.convertedValue),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 45,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Theme(
                // Forzamos sombras claras pero usamos el color de texto del tema oscuro
                data: lightTheme.copyWith(
                  colorScheme: lightTheme.colorScheme.copyWith(
                    onPrimary: AppTheme.darkTheme.colorScheme.onPrimary,
                  ),
                ),
                child: ActionButton(
                  icon: Icons.add_shopping_cart,
                  label: "Guardar Precio",
                  onPressed: widget.onSave,
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
