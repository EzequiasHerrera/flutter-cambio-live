import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/screens/home_screen.dart';
import 'package:howmuch/screens/camera_screen.dart';
import 'package:howmuch/screens/cart_screen.dart';
import 'package:howmuch/screens/calculator_screen.dart';
import 'package:howmuch/theme/app_theme.dart';
import 'package:device_preview/device_preview.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Insets & Edge-to-Edge: Aprovechar toda la pantalla (Requerido para Android 15+)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 2. Adaptabilidad: Permitir orientaciones horizontales para Pantallas Grandes/Tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 3. Estilo del Sistema: Barras transparentes
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  //runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: MaterialApp(
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,

        title: 'Howmuch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/camera': (context) => const CameraScreen(),
          '/cart': (context) => const CartScreen(),
          '/calculator': (context) => const CalculatorScreen(),
        },
      ),
    );
  }
}
