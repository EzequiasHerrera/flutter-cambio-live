import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'action_button.dart';

class CustomCurrencyDialog extends StatefulWidget {
  const CustomCurrencyDialog({super.key});

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

    // Animación infinita de rebote
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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
          content: const Text('Ingresa un nombre y valor válido'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
          // ESTRELLA ANIMADA INFINITA
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 8 * Curves.easeInOut.transform(_floatingController.value)),
                child: child,
              );
            },
            child: Icon(
              Icons.grade_rounded,
              color: colorScheme.primary,
              size: 50,
            ),
          ),
          const SizedBox(height: 15),
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
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre de la moneda',
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
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colorScheme.secondary)),
            ),
          ],
        ),
      ],
    );
  }
}
