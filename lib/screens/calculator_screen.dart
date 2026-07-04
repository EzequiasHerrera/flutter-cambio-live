import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/widgets/action_button.dart';
import 'package:howmuch/widgets/bubble_dialog.dart';
import 'package:howmuch/widgets/howie.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:howmuch/widgets/price_card.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  double? _val;
  double? _conv;
  String _txt = "";

  @override
  void initState() {
    super.initState();
    // Auto focus on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _txt = "";
        _val = null;
        _conv = null;
      });
      return;
    }

    final cleanedValue = value.replaceAll(',', '.');
    final val = double.tryParse(cleanedValue);

    if (val != null) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      setState(() {
        _txt = value;
        _val = val;
        _conv = provider.convert(val);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(showCart: true),
      backgroundColor: colorScheme.surface,
      // Dejamos que el Scaffold maneje el ajuste del teclado automáticamente
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // 1. Howie y su mensaje: Fijos en la parte superior
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                const SizedBox(
                  height: 160, // Un poco más grande
                  width: 140,
                  child: Howie(),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: BubbleDialog(
                    message: "A veces lo viejo funciona...",
                    direction: BubbleDirection.left,
                  ),
                ),
              ],
            ),
          ),

          // 2. Área scrollable para el input y la tarjeta
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Entrada de precio
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precio en ${provider.baseCurrency?.code}',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: "0.00",
                                  hintStyle: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(0.1)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                                ],
                                onChanged: _onChanged,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Tarjeta de precio: SIEMPRE visible
                  PriceCard(
                    text: _txt.isEmpty ? "0.00" : _txt,
                    convertedValue: _conv ?? 0.0,
                    currencyCode: provider.targetCurrency?.code ?? '',
                    onSave: () {
                      if (_val != null && _val! > 0) {
                        provider.addToCart(_val!, _conv!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Guardado en el carrito!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa un precio primero'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  
                  // Espacio final para asegurar que se pueda scrollear sobre el teclado
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
