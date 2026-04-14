import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Importamos el tema

class CurrencyCard extends StatelessWidget {
  final String label;
  final Widget child;

  const CurrencyCard({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Color de fondo propio
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        boxShadow: [
          AppTheme.getHardShadow(
              colorScheme,
              isPrimary: false
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          child,
        ],
      ),
    );
  }
}