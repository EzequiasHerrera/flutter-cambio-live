import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'action_button.dart'; // Importamos el ActionButton
import 'dart:math' as math;

class CustomCurrencyDialog extends StatefulWidget {
  const CustomCurrencyDialog({super.key});

  // Metodo estático para mostrar el diálogo fácilmente
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CustomCurrencyDialog(),
    );
  }

  @override
  State<CustomCurrencyDialog> createState() => _CustomCurrencyDialogState();
}

class _CustomCurrencyDialogState extends State<CustomCurrencyDialog>
    with SingleTickerProviderStateMixin {

  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.customName);
    _rateController = TextEditingController(
      text: provider.customRate > 0 ? provider.customRate.toString() : '',
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Velocidad del rebote
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    final rateText = _rateController.text.trim().replaceAll(',', '.');
    final rate = double.tryParse(rateText);

    if (name.isNotEmpty && rate != null && rate > 0) {
      context.read<AppProvider>().setCustomCurrency(name, rate);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa un nombre y valor válido (ej: 1250.50)'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Column(
        children: [
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 3 * Curves.easeInOut.transform(_floatingController.value)),
                child: child,
              );
            },
            child: Icon(
              Icons.grade_rounded,
              color: colorScheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Moneda Personalizada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre de la moneda',
                hintText: 'ej: Dólar Blue',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Tasa de cambio',
                hintText: 'ej: 1150.00',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Valor respecto a 1 USD',
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 20, left: 20, bottom: 20),
      actions: [
        Column(
          children: [
            ActionButton(
              icon: Icons.save,
              label: 'Guardar y Activar',
              onPressed: _onSave,
              isPrimary: true,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: colorScheme.secondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
