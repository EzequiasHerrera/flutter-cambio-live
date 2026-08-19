import 'package:flutter/material.dart';
import 'package:howmuch/theme/app_theme.dart';
import 'package:howmuch/widgets/currency_icon.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:howmuch/widgets/howie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/models/cart_item.dart';
import 'package:howmuch/widgets/bubble_dialog.dart';
import 'package:howmuch/services/feedback_service.dart';

import '../widgets/howie_barriendo.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _tapCount = 0;

  void _incrementCounter() {
    setState(() {
      _tapCount++;
    });
    FeedbackService.light();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.cart.isEmpty) {
            return Center(
              child: Transform.translate(
                offset: const Offset(0, -100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const BubbleDialog(
                      message: 'Bien limpio, sin nada 🛒',
                      direction: BubbleDirection.bottom,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: HowieBarriendo(
                        onTap: _incrementCounter,
                      ),
                    ),
                    if (_tapCount > 0) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$_tapCount',
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary.withOpacity(0.2),
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.cart.length,
                  itemBuilder: (context, index) {
                    final CartItem item = provider.cart[index];
                    return _CartItemWidget(
                      item: item,
                      onDelete: () => provider.removeFromCart(index),
                    );
                  },
                ),
              ),
              _buildFooter(provider, colorScheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-15, 0),
            child: const SizedBox(
              width: 120,
              height: 140,
              child: Howie(),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus precios guardados 📝',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Aquí podés ver todo lo que agregaste a tu lista.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppProvider provider, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.12),
            offset: const Offset(0, -10),
            blurRadius: 30,
          )
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.primary.withOpacity(0.1),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pequeño indicador decorativo
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL A PAGAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.cart.length} productos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow,
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: Text(
                    formatCurrency(
                      provider.totalSaved,
                      provider.targetCurrency?.code ?? '',
                      provider.targetCurrency?.symbol ?? '',
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemWidget extends StatefulWidget {
  final CartItem item;
  final VoidCallback onDelete;

  const _CartItemWidget({
    required this.item,
    required this.onDelete,
  });

  @override
  State<_CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<_CartItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double offset = _isPressed ? 4.0 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outlineVariant,
            offset: const Offset(0, 6),
            blurRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parte Superior: Bandera Origen, Siglas, Valor Original, Flecha
                  Row(
                    children: [
                      CurrencyIcon(
                        currencyCode: widget.item.originalCurrency.code,
                        width: 20,
                        height: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatCurrency(
                          widget.item.originalAmount,
                          widget.item.originalCurrency.code,
                          widget.item.originalCurrency.code,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Parte Inferior: Bandera Destino, Valor Destino
                  Row(
                    children: [
                      CurrencyIcon(
                        currencyCode: widget.item.targetCurrency.code,
                        width: 28,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatCurrency(
                          widget.item.targetAmount,
                          widget.item.targetCurrency.code,
                          widget.item.targetCurrency.symbol,
                        ),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('HH:mm - dd/MM/yy').format(widget.item.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Botón de borrar con estética de la app: ROJO con icono BLANCO
            GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                FeedbackService.vibrate();
                widget.onDelete();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, offset, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: Colors.red.shade900.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B0000), // Rojo Bordó Oscuro
                      offset: Offset(0, 6 - offset),
                      blurRadius: 0,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para formatear monedas con separadores de miles y decimales
String formatCurrency(double amount, String code, String symbol) {
  // Determinamos el locale básico según la moneda para el formato de puntos y comas
  // es_AR: 1.234,56 | en_US: 1,234.56
  String locale = 'es_AR'; 
  if (['USD', 'GBP', 'JPY', 'CAD', 'AUD'].contains(code)) {
    locale = 'en_US';
  }

  final formatter = NumberFormat.decimalPattern(locale);
  formatter.minimumFractionDigits = 2;
  formatter.maximumFractionDigits = 2;

  String prefix = symbol.isEmpty ? code : symbol;
  
  // Si es un símbolo corto ($) lo pegamos, si es sigla (USD) dejamos espacio
  return prefix.length <= 1 
      ? '$prefix${formatter.format(amount)}' 
      : '$prefix ${formatter.format(amount)}';
}
