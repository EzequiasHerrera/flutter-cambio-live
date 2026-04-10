import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/currency.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customRateController = TextEditingController();

  @override
  void dispose() {
    _customNameController.dispose();
    _customRateController.dispose();
    super.dispose();
  }

  void _showCustomCurrencyDialog(AppProvider provider) {
    _customNameController.text = provider.customName;
    _customRateController.text = provider.customRate.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moneda Personalizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customNameController,
              decoration: const InputDecoration(labelText: 'Nombre (ej: Dolar Pepino)'),
            ),
            TextField(
              controller: _customRateController,
              decoration: const InputDecoration(labelText: 'Valor (Tasa de cambio)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _customNameController.text;
              final rate = double.tryParse(_customRateController.text) ?? 1.0;
              provider.setCustomCurrency(name, rate);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return Text('Howmuch', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary));
          },
        ),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.availableCurrencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final double unitRate = provider.convert(1.0);
          final String baseCode = provider.baseCurrency?.code ?? '';
          final String targetCode = provider.useCustomCurrency ? provider.customName : (provider.targetCurrency?.code ?? '');

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Seleccione las Monedas',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          _buildCurrencyCard(
                            label: 'Desde (Cámara)',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Currency>(
                                isExpanded: true,
                                value: provider.baseCurrency,
                                items: provider.availableCurrencies.map((Currency c) {
                                  return DropdownMenuItem<Currency>(
                                    value: c,
                                    child: Text('${c.code} - ${c.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                                onChanged: (val) => provider.setBaseCurrency(val!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildCurrencyCard(
                            label: 'Hacia (Ver)',
                            child: Row(
                              children: [
                                Expanded(
                                  child: provider.useCustomCurrency 
                                    ? Text(provider.customName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary))
                                    : DropdownButtonHideUnderline(
                                        child: DropdownButton<Currency>(
                                          isExpanded: true,
                                          value: provider.targetCurrency,
                                          items: provider.availableCurrencies.map((Currency c) {
                                            return DropdownMenuItem<Currency>(
                                              value: c,
                                              child: Text('${c.code} - ${c.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            );
                                          }).toList(),
                                          onChanged: (val) => provider.setTargetCurrency(val!),
                                        ),
                                      ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_note, color: provider.useCustomCurrency ? colorScheme.secondary : Colors.grey),
                                  onPressed: () => _showCustomCurrencyDialog(provider),
                                  tooltip: 'Configurar Moneda Personalizada',
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        child: GestureDetector(
                          onTap: provider.useCustomCurrency ? null : () => provider.swapCurrencies(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: provider.useCustomCurrency ? Colors.grey : colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.swap_vert, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primaryContainer.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '1 $baseCode = ${unitRate.toStringAsFixed(2)} $targetCode',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildActionButton(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Ir a la Cámara',
                    onPressed: () => Navigator.pushNamed(context, '/camera'),
                    isPrimary: true,
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    context: context,
                    icon: Icons.shopping_cart,
                    label: 'Ver Carrito',
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    isPrimary: false,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrencyCard({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({required BuildContext context, required IconData icon, required String label, required VoidCallback onPressed, required bool isPrimary}) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isPrimary 
        ? ElevatedButton.icon(
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontSize: 18)),
            // Nota: El estilo ya viene definido en el theme global del main.dart
            onPressed: onPressed,
          )
        : OutlinedButton.icon(
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontSize: 18)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onPressed,
          ),
    );
  }
}
