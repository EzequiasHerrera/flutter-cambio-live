import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:howmuch/theme/app_theme.dart';

class CurrencyIcon extends StatelessWidget {
  final String currencyCode;
  final double width;
  final double height;

  const CurrencyIcon({
    super.key,
    required this.currencyCode,
    this.width = 32,
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Obtenemos el código de país mapeado (usando la lógica del modelo o similar)
    // Para simplificar, repetimos la lógica de mapeo aquí o la llamamos del modelo
    String flagCode = currencyCode;
    if (currencyCode == 'EUR') flagCode = 'EU';

    // 🌟 CASO 1: MONEDA PERSONALIZADA
    if (currencyCode == 'CUSTOM') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Icon(
          Icons.auto_awesome_rounded, // Icono "mágico" para personalizada
          size: 14,
          color: colorScheme.primary,
        ),
      );
    }

    // 🚩 CASO 2: BANDERAS NORMALES
    if (flagCode.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.help_outline, size: 12),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Flag.fromString(
        flagCode.length >= 2 ? flagCode.substring(0, 2) : flagCode,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}
