import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import '../models/currency.dart';

class CurrencyIcon extends StatelessWidget {
  final Currency currency;
  final double width;
  final double height;

  const CurrencyIcon({
    super.key,
    required this.currency,
    this.width = 32,
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 🌟 CASO 1: MONEDA PERSONALIZADA
    if (currency.isCustom) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 14,
          color: colorScheme.primary,
        ),
      );
    }

    // 🚩 CASO 2: BANDERAS NORMALES
    final String flagCode = currency.flagCode;
    
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
        flagCode,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}
