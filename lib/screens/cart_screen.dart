import 'package:flutter/material.dart';
import 'package:howmuch/widgets/custom_app_bar.dart';
import 'package:howmuch/widgets/howie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.cart.isEmpty) {
            return Center(
              child: Transform.translate(
                offset: const Offset(0, -100),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centrado Vertical
                  crossAxisAlignment: CrossAxisAlignment.center, // Centrado Horizontal
                  children: [
                    SizedBox(
                      height: 200,
                      child: Howie(),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'El carrito está vacío 🛒',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
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
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.monetization_on, color: Colors.green),
                        title: Text(
                          '${item.originalCurrency.code} ${item.originalAmount.toStringAsFixed(2)}  ➔  ${item.targetCurrency.code} ${item.targetAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm').format(item.timestamp)),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '${provider.targetCurrency?.code ?? ''} ${provider.totalSaved.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
