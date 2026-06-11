import 'package:flutter/material.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:howmuch/widgets/howie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/models/cart_item.dart';
import 'package:howmuch/widgets/bubble_dialog.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BubbleDialog(
                      message: 'El carrito está vacío 🛒',
                      direction: BubbleDirection.bottom,
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: Howie(),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: provider.cart.length,
                  itemBuilder: (context, index) {
                    final CartItem item = provider.cart[index];
                    return Card(
                      elevation: 0,
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.monetization_on,
                              color: colorScheme.primary),
                        ),
                        title: Text(
                          '${item.originalCurrency.code} ${item.originalAmount.toStringAsFixed(2)}  ➔  ${item.targetCurrency.code} ${item.targetAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd – kk:mm')
                              .format(item.timestamp),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            // TODO: Implementar eliminación de item si se desea
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${provider.targetCurrency?.code ?? ''} ${provider.totalSaved.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
