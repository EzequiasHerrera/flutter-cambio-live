import 'package:flutter/material.dart';
import 'package:howmuch/models/currency.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/theme/app_theme.dart';
import 'package:howmuch/widgets/action_button.dart';
import 'package:howmuch/widgets/currency_card.dart';
import 'package:howmuch/widgets/currency_icon.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:howmuch/widgets/custom_currency_dialog.dart';
import 'package:howmuch/widgets/howie.dart';
import 'package:howmuch/widgets/swap_button.dart';
import 'package:provider/provider.dart';

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

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildConverterCard(context, provider, colorScheme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(-25, 0),
          child: const SizedBox(
            width: 160,
            height: 200,
            child: Howie(),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Vamos de compras? 🛍️',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Convertí precios en segundos y descubrí cuánto cuestan realmente.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConverterCard(
    BuildContext context,
    AppProvider provider,
    ColorScheme colorScheme,
  ) {
    final double unitRate = provider.convert(1.0);
    final String baseCode = provider.baseCurrency?.code ?? '';
    final String targetCode =
        provider.useCustomCurrency ? provider.customName : (provider.targetCurrency?.code ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [AppTheme.getHardShadow(colorScheme)]),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  _buildCurrencySelector(
                    label: 'Desde (Cámara)',
                    value: provider.baseCurrency,
                    items: provider.availableCurrencies,
                    onChanged: (val) => provider.setBaseCurrency(val!),
                  ),
                  const SizedBox(height: 15),
                  _buildTargetSelector(context, provider, colorScheme),
                ],
              ),
              const Positioned(child: SwapButton()),
            ],
          ),
          const SizedBox(height: 30),
          _buildRateInfo(colorScheme, baseCode, unitRate, targetCode),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String label,
    required Currency? value,
    required List<Currency> items,
    required ValueChanged<Currency?> onChanged,
  }) {
    return CurrencyCard(
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Currency>(
          isExpanded: true,
          value: value,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          items: items.map((Currency c) {
            return DropdownMenuItem<Currency>(
              value: c,
              child: Row(
                children: [
                  CurrencyIcon(currencyCode: c.code),
                  const SizedBox(width: 10),
                  Text(
                    '${c.code} - ${c.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTargetSelector(
    BuildContext context,
    AppProvider provider,
    ColorScheme colorScheme,
  ) {
    return CurrencyCard(
      label: 'Hacia (Ver)',
      child: Row(
        children: [
          Expanded(
            child: provider.useCustomCurrency
                ? Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text(
                        provider.customName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
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
                              Text(
                                '${c.code} - ${c.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
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
                icon: Icon(
                  Icons.edit_rounded,
                  color: provider.useCustomCurrency ? colorScheme.primary : Colors.grey,
                ),
                onPressed: () => CustomCurrencyDialog.show(context),
              ),
              if (provider.useCustomCurrency)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                  onPressed: () => provider.disableCustomCurrency(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateInfo(
    ColorScheme colorScheme,
    String baseCode,
    double unitRate,
    String targetCode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.tertiary.withAlpha(50),
          width: 1,
        ),
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
                color: colorScheme.tertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildNavButton(
              context,
              icon: Icons.currency_exchange_rounded,
              label: 'Conversor',
              onPressed: () => Navigator.pushNamed(context, '/calculator'),
              isPrimary: false,
            ),
            const SizedBox(width: 15),
            _buildNavButton(
              context,
              icon: Icons.camera_alt_rounded,
              label: 'Cámara',
              onPressed: () => Navigator.pushNamed(context, '/camera'),
              isPrimary: true,
            ),
            const SizedBox(width: 15),
            _buildNavButton(
              context,
              icon: Icons.shopping_cart_rounded,
              label: 'Carrito',
              onPressed: () => Navigator.pushNamed(context, '/cart'),
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ActionButton(
            icon: icon,
            onPressed: onPressed,
            isPrimary: isPrimary,
          ),
        ],
      ),
    );
  }
}

