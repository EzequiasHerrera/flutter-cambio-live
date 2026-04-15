import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showCart;

  const CustomAppBar({
    super.key,
    this.showCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      systemOverlayStyle: isDarkMode
      ? SystemUiOverlayStyle.dark
      : SystemUiOverlayStyle.light,

      // 1. Forzamos transparencia absoluta
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,

      // Importante: quitamos el centrado automático de Flutter si da problemas de espacio
      centerTitle: true,

      // 2. Botón de volver con mejor visibilidad sobre cámara
      leading: Navigator.canPop(context)
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.2), // Fondo sutil para ver el ícono sobre la cámara
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: Colors.white, // Blanco resalta mejor sobre video
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      )
          : null,

      // 3. Título (Logo) envuelto en un Container para asegurar que no se corte
      title: Container(
        constraints: const BoxConstraints(maxHeight: 40),
        child: SvgPicture.asset(
          'assets/icon/ic_howmuch.svg',
          fit: BoxFit.contain, // 👈 Evita que se corte
          placeholderBuilder: (_) => Text(
            'Howmuch',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary
            ),
          ),
        ),
      ),

      // 4. Botón de Carrito
      actions: [
        if (showCart)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
                color: Colors.white,
              ),
            ),
          ),
        // Si no hay carrito, añadimos un espacio vacío del mismo tamaño que el 'leading'
        // para que el logo quede perfectamente centrado.
        if (!showCart) const SizedBox(width: 56),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}