import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:howmuch/theme/app_theme.dart';

class ActionButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double width;

  const ActionButton({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.width = double.infinity,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double offset = _isPressed ? 4.0 : 0.0;
    
    final baseShadow = AppTheme.getHardShadow(colorScheme, isPrimary: widget.isPrimary);
    final activeShadow = BoxShadow(
      color: baseShadow.color,
      offset: Offset(0, 6 - offset),
      blurRadius: 0,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, offset, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [activeShadow],
      ),
      child: SizedBox(
        width: widget.width,
        height: 55,
        child: widget.label != null 
          ? ElevatedButton.icon(
              onPressed: _handlePress,
              icon: Icon(widget.icon, size: 30),
              label: Text(widget.label!),
              style: _buildStyle(colorScheme),
            )
          : ElevatedButton(
              onPressed: _handlePress,
              style: _buildStyle(colorScheme),
              child: Icon(widget.icon, size: 30),
            ),
      ),
    );
  }

  void _handlePress() {
    HapticFeedback.vibrate();
    setState(() => _isPressed = true);
    widget.onPressed();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  ButtonStyle _buildStyle(ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.isPrimary ? colorScheme.primary : colorScheme.surface,
      foregroundColor: widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: widget.label == null ? EdgeInsets.zero : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: widget.isPrimary ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
    );
  }
}
