import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:howmuch/theme/app_theme.dart';
import 'package:howmuch/widgets/action_button.dart';import 'package:howmuch/widgets/currency_card.dart';
import 'package:howmuch/widgets/currency_icon.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/app_provider.dart';
import '../models/currency.dart';
import 'package:lottie/lottie.dart';

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
    // 1. Recuperamos el esquema de colores actual (Soporta Light/Dark)
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(showCart: false),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.availableCurrencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final double unitRate = provider.convert(1.0);
          final String baseCode = provider.baseCurrency?.code ?? '';
          final String targetCode = provider.useCustomCurrency
              ? provider.customName
              : (provider.targetCurrency?.code ?? '');

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 180,
                    child: Lottie.asset(
                      'assets/animations/Howie_Home.json',
                      repeat: true,
                      animate: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Text(
                    'Vamos de compras?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // SECCIÓN DE CARDS
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          CurrencyCard(
                            label: 'Desde (Cámara)',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Currency>(
                                isExpanded: true,
                                value: provider.baseCurrency,
                                borderRadius: BorderRadius.circular(AppTheme.radius),
                                items: provider.availableCurrencies.map((Currency c) {
                                  return DropdownMenuItem<Currency>(
                                    value: c,
                                    child: Row(
                                      children: [
                                        CurrencyIcon(currencyCode: c.code),
                                        const SizedBox(width: 10),
                                        Text('${c.code} - ${c.name}',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => provider.setBaseCurrency(val!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          CurrencyCard(
                            label: 'Hacia (Ver)',
                            child: Row(
                              children: [
                                Expanded(
                                  child: provider.useCustomCurrency
                                      ? Text(provider.customName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary))
                                      : DropdownButtonHideUnderline(
                                    child: DropdownButton<Currency>(
                                      isExpanded: true,
                                      value: provider.targetCurrency,
                                      borderRadius: BorderRadius.circular(AppTheme.radius),
                                      items: provider.availableCurrencies.map((Currency c) {
                                        return DropdownMenuItem<Currency>(
                                          value: c,
                                          child: Row(
                                            children: [
                                              CurrencyIcon(currencyCode: c.code),
                                              const SizedBox(width: 10),
                                              Text('${c.code} - ${c.name}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => provider.setTargetCurrency(val!),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_note,
                                      color: provider.useCustomCurrency ? colorScheme.primary : Colors.grey),
                                  onPressed: () => _showCustomCurrencyDialog(provider),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),

                      // BOTÓN SWAP
                      Positioned(
                        child: GestureDetector(
                          onTap: provider.useCustomCurrency ? null : () => provider.swapCurrencies(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: provider.useCustomCurrency ? Colors.grey : colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 4),
                              boxShadow: [
                                // Pasamos el colorScheme para que la sombra sepa qué color usar
                                AppTheme.getHardShadow(colorScheme, isPrimary: false)
                              ],
                            ),
                            child: const Icon(Icons.swap_calls_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // BANNER DE INFORMACIÓN
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.tertiary.withAlpha(50), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.tertiary, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '1 $baseCode = ${unitRate.toStringAsFixed(2)} $targetCode',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.tertiary
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // BOTONES DE ACCIÓN
                  ActionButton(
                      icon: Icons.camera_alt,
                      label: 'Ir a la Cámara',
                      onPressed: () => Navigator.pushNamed(context, '/camera'),
                      isPrimary: true
                  ),
                  const SizedBox(height: 15),
                  ActionButton(
                      icon: Icons.shopping_cart,
                      label: 'Ver Carrito',
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                      isPrimary: false
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}