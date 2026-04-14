import 'package:flutter/material.dart';
import 'package:howmuch/theme/app_theme.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos el esquema de colores actual (sea claro u oscuro)
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        // LE PASAMOS EL COLORSCHEME PARA QUE SEPA QUÉ COLOR DE SOMBRA USAR
        boxShadow: [
          AppTheme.getHardShadow(
              colorScheme,
              isPrimary: isPrimary
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 30),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? colorScheme.primary
                : colorScheme.surface,
            foregroundColor: isPrimary
                ? colorScheme.onPrimary
                : colorScheme.primary,
            elevation: 0,
            side: isPrimary
                ? null
                : BorderSide(color: colorScheme.outlineVariant, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
          )
        ),
      ),
    );
  }
}