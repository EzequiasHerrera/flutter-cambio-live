import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:howmuch/providers/app_provider.dart';
import 'package:howmuch/screens/home_screen.dart';
import 'package:howmuch/screens/camera_screen.dart';
import 'package:howmuch/screens/cart_screen.dart';
import 'package:howmuch/screens/calculator_screen.dart';
import 'package:howmuch/theme/app_theme.dart';

void main() {
  runApp(DevicePreview(builder: (context) => const MyApp()));
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
