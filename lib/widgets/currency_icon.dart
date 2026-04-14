import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../theme/app_theme.dart';

class CurrencyIcon extends StatelessWidget {final String currencyCode;
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
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded, // Icono "mágico" para personalizada
        size: 14,
        color: AppTheme.primaryColor,
      ),
    );
  }

  // 🚩 CASO 2: BANDERAS NORMALES
  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: CountryFlag.fromCountryCode(
      flagCode.length >= 2 ? flagCode.substring(0, 2) : flagCode,
      width: width,
      height: height,
    ),
  );
}
}