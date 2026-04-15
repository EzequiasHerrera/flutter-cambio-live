import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/theme/app_theme.dart';
import 'dart:math' as math;

class SwapButton extends StatefulWidget {
  const SwapButton({super.key});

  @override
  State<SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<SwapButton> {
  bool _isPressed = false;
  double _angle = 0.0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final double offset = _isPressed ? 4.0 : 0.0;

    final baseShadow = AppTheme.getHardShadow(colorScheme);
    final activeShadow = BoxShadow(
      color: baseShadow.color,
      offset: Offset(0, 6 - offset),
      blurRadius: 0,
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (!provider.useCustomCurrency) {
          provider.swapCurrencies();
          setState(() {
            _angle += math.pi;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0.0, offset, 0.0),

        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: provider.useCustomCurrency ? Colors.grey : colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.surface, width: 4),
          boxShadow: [activeShadow],
        ),

        // 2. Usamos AnimatedRotation para girar SOLO el icono
        child: AnimatedRotation(
          turns: _angle / (2 * math.pi), // Convierte radianes a vueltas
          duration: const Duration(milliseconds: 200), // Un poco más lento para que se note
          curve: Curves.easeInOut,
          child: const Icon(
            Icons.swap_calls_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}