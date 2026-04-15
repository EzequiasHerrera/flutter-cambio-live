import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CustomCurrencyDialog extends StatefulWidget {
  const CustomCurrencyDialog({super.key});

  // Metodo estático para mostrar el diálogo fácilmente
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite cerrar al tocar fuera
      builder: (context) => const CustomCurrencyDialog(),
    );
  }

  @override
  State<CustomCurrencyDialog> createState() => _CustomCurrencyDialogState();
}

class _CustomCurrencyDialogState extends State<CustomCurrencyDialog> {
  late TextEditingController _nameController;
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    // Obtenemos los valores actuales del provider para precargar los campos
    final provider = Provider.of<AppProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.customName);

    // Si el rate es 0 o inicial, podrías preferir mostrar cadena vacía o el valor actual
    _rateController = TextEditingController(
        text: provider.customRate > 0 ? provider.customRate.toString() : ''
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    // Reemplazamos coma por punto para que double.tryParse no falle
    final rateText = _rateController.text.trim().replaceAll(',', '.');
    final rate = double.tryParse(rateText);

    if (name.isNotEmpty && rate != null && rate > 0) {
      context.read<AppProvider>().setCustomCurrency(name, rate);
      Navigator.pop(context); // Cerramos el diálogo
    } else {
      // Feedback visual rápido si hay error
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
      surfaceTintColor: Colors.transparent, // Evita el tinte automático de Material 3
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Column(
        children: [
          Icon(Icons.dashboard_customize_rounded, color: colorScheme.primary, size: 40),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tasa de cambio',
                hintText: 'ej: 1150.00',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Valor respecto a 1 USD',
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: colorScheme.secondary)),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Guardar y Activar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}