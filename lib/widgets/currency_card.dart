import 'package:flutter/material.dart';
import 'package:howmuch/theme/app_theme.dart';

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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          child,
        ],
      ),
    );
  }
}