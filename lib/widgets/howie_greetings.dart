import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

class HowieGreetings extends StatelessWidget {
  const HowieGreetings({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/Howie_Greetings.json',
      repeat: true,
      animate: true,
      fit: BoxFit.cover,
    );
  }
}
