import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:howmuch/logic/debug_state.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showCart;

  const CustomAppBar({
    super.key,
    this.showCart = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  int _counter = 0;
  void _handleTap(){
    setState(() {
    _counter++;
    });

    if (_counter >= 8){
      DebugState.instance.toggleDebugMode();
      _counter = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      systemOverlayStyle: isDarkMode
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark,

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
          backgroundColor: Colors.black.withOpacity(0.2),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: Colors.white,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      )
          : null,

      title: GestureDetector(
        onTap: _handleTap,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 40),
          child: SvgPicture.asset(
            'assets/icon/ic_howmuch.svg',
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              colorScheme.primary,
              BlendMode.srcIn,
            ),
            placeholderBuilder: (_) => Text(
              'Howmuch',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary
              ),
            ),
          ),
        ),
      ),

      // 4. Botón de Carrito
      actions: [
        if (widget.showCart)
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
        if (!widget.showCart) const SizedBox(width: 56),
      ],
    );
  }
}