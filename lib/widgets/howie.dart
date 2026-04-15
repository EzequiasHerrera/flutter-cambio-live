import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

class Howie extends StatelessWidget {
  const Howie({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/Howie_Home.json',
      repeat: true,
      animate: true,
      fit: BoxFit.cover,
    );
  }
}
