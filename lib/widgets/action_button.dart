import 'package:flutter/material.dart';
import 'package:howmuch/theme/app_theme.dart';

class ActionButton extends StatefulWidget {
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
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculamos el desplazamiento: 4px hacia abajo cuando se presiona
    final double offset = _isPressed ? 4.0 : 0.0;
    
    // Obtenemos la sombra base y le restamos el desplazamiento para que parezca que se "hunde"
    final baseShadow = AppTheme.getHardShadow(colorScheme, isPrimary: widget.isPrimary);
    final activeShadow = BoxShadow(
      color: baseShadow.color,
      offset: Offset(0, 6 - offset), // La sombra se acorta al bajar el botón
      blurRadius: 0,
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, offset, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [activeShadow],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, size: 30),
            label: Text(widget.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isPrimary
                  ? colorScheme.primary
                  : colorScheme.surface,
              foregroundColor: widget.isPrimary
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
              elevation: 0,
              side: widget.isPrimary
                  ? null
                  : BorderSide(color: colorScheme.outlineVariant, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
