import 'package:flutter/material.dart';
import 'package:howmuch/theme/app_theme.dart';
import 'package:howmuch/widgets/action_button.dart';
import 'package:howmuch/widgets/currency_card.dart';
import 'package:howmuch/widgets/currency_icon.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:howmuch/widgets/howie.dart';
import 'package:howmuch/widgets/swap_button.dart';
import 'package:howmuch/widgets/custom_currency_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/currency.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 200, child: Howie()),
                  const Text(
                    'Vamos de compras?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

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
                                      ? Row(
                                    children: [
                                      const Icon(Icons.stars_rounded, color: Colors.orange),
                                      const SizedBox(width: 10),
                                      Text(provider.customName,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                                    ],
                                  )
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_rounded,
                                          color: provider.useCustomCurrency ? colorScheme.primary : Colors.grey),
                                      onPressed: () => CustomCurrencyDialog.show(context), // Llamada limpia
                                    ),
                                    if (provider.useCustomCurrency)
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                                        onPressed: () => provider.disableCustomCurrency(),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Positioned(child: SwapButton()),
                    ],
                  ),

                  const SizedBox(height: 30),

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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.tertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

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
