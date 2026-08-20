import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:howmuch/widgets/bubble_dialog.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'howie_greetings.dart';

class Tutorial {
  // Un metodo estático para no tener que instanciar la clase
  static void show({
    required BuildContext context,
    required GlobalKey keyConvertidor,
    required GlobalKey keyHowie,
  }) {
    // 1. Armamos los pasos
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "paso_gasto",
        keyTarget: keyHowie,
        shape: ShapeLightFocus.RRect,
        radius: 40,
        paddingFocus: 10,

        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BubbleDialog(
                  message:
                      "¡Hola! Soy Howie. Seré tu acompañante en este viaje ✈️🗺️",
                  direction: BubbleDirection.bottom,
                ),
                const SizedBox(height: 20),
                const HowieGreetings(),
                // SvgPicture.asset(
                //   'assets/images/howie_greetings.svg',
                //   height: 200,
                // ),
              ],
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "paso_convert",
        keyTarget: keyConvertidor,
        shape: ShapeLightFocus.RRect,
        radius: 40,
        paddingFocus: 10,

        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BubbleDialog(
                  message: "Te voy a agarrar a trompadas! ✈️🗺️",
                  direction: BubbleDirection.bottom,
                ),
                const SizedBox(height: 20),
                const HowieGreetings(),
                // SvgPicture.asset(
                //   'assets/images/howie_greetings.svg',
                //   height: 200,
                // ),
              ],
            ),
          ),
        ],
      ),
    ];

    // 2. Disparación de la librería
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      focusAnimationDuration: const Duration(
        milliseconds: 1500,
      ), // Hace la transición más suave
      pulseEnable: false,
    ).show(context: context);
  }
}
