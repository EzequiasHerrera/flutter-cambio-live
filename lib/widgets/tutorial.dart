import 'package:flutter/material.dart';
import 'package:howmuch/widgets/bubble_dialog.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'howie_greetings.dart';

class Tutorial {
  static void show({
    required BuildContext context,
    List<TargetFocus>? targets,
    VoidCallback? onFinish,
  }) {
    if (targets == null || targets.isEmpty) return;

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      focusAnimationDuration: const Duration(milliseconds: 600),
      unFocusAnimationDuration: const Duration(milliseconds: 600),
      pulseEnable: false,
      onFinish: onFinish,
      onSkip: () {
        onFinish?.call();
        return true;
      },
    ).show(context: context);
  }

  static TargetContent howieAndBubbleDialog({
    ContentAlign align = ContentAlign.top,
    double? howieTop,
    double? howieBottom,
    double? howieLeft,
    double? howieRight,
    double howieAngle = 0,
    double howieSize = 0,
    double? bubbleTop,
    double? bubbleBottom,
    double? bubbleLeft,
    double? bubbleRight,
    bool animation = false,
    String bubbleText = "No hay texto aún",
    BubbleDirection bubbleDirection = BubbleDirection.bottom,
  }) {
    return TargetContent(
      align: align,
      child: Builder(builder: (context) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 240,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              if (howieSize > 0)
                Positioned(
                  top: howieTop,
                  bottom: howieBottom,
                  left: howieLeft,
                  right: howieRight,
                  child: Transform.rotate(
                    angle: howieAngle * (3.1416 / 180),
                    child: SizedBox(
                      height: howieSize,
                      child: animation ? null : const HowieGreetings(),
                    ),
                  ),
                ),
              Positioned(
                top: bubbleTop,
                bottom: bubbleBottom,
                left: bubbleLeft ?? 20,
                right: bubbleRight ?? 20,
                child: Center(
                  child: BubbleDialog(
                    message: bubbleText,
                    direction: bubbleDirection,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // --- PASOS PARA HOME ---
  static List<TargetFocus> homeTargets({
    required GlobalKey keyHowie,
    required GlobalKey keyConvertidor,
    required GlobalKey keyCustom,
    required GlobalKey keyMenu,
  }) {
    return [
      TargetFocus(
        identify: "home_howie",
        keyTarget: keyHowie,
        shape: ShapeLightFocus.RRect,
        radius: 40,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.bottom,
            howieBottom: 0,
            howieSize: 220,
            bubbleBottom: 225,
            bubbleText:
                "¡Bienvenido a Howmuch! Soy Howie, te voy a mostrar el lugar. Preparado? 🧡✈️",
            bubbleDirection: BubbleDirection.top,
          ),
        ],
      ),
      TargetFocus(
        identify: "home_convert",
        keyTarget: keyConvertidor,
        shape: ShapeLightFocus.RRect,
        radius: 40,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.top,
            howieBottom: -120,
            howieRight: 310,
            howieAngle: 45,
            howieSize: 200,
            bubbleBottom: 20,
            bubbleText: "Elegí la moneda origen y a la que querés convertir 💱🪙",
            bubbleDirection: BubbleDirection.middlebottom,
          ),
        ],
      ),
      TargetFocus(
        identify: "home_custom",
        keyTarget: keyCustom,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.top,
            howieBottom: -120,
            howieRight: 310,
            howieAngle: 45,
            howieSize: 200,
            bubbleBottom: 20,
            bubbleText:
                "No encontrás tu moneda? Creala y asignale un valor personalizado. Sin sorpresas! ⭐️",
            bubbleDirection: BubbleDirection.middlebottom,
          ),
        ],
      ),
      TargetFocus(
        identify: "home_menu",
        keyTarget: keyMenu,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.top,
            howieBottom: -40,
            howieRight: 140,
            howieSize: 180,
            bubbleBottom: 20,
            bubbleText:
                "Este es el navegador hacia el conversor manual 💱, tu carrito de compras 🛒 o directo a la camara 📷",
            bubbleDirection: BubbleDirection.middlebottom,
          ),
        ],
      ),
    ];
  }

  // --- PASOS PARA CALCULADORA ---
  static List<TargetFocus> conversorTargets({required GlobalKey keyInput}) {
    return [
      TargetFocus(
        identify: "conv_input",
        keyTarget: keyInput,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.top,
            howieBottom: -40,
            howieRight: 140,
            howieSize: 150,
            bubbleBottom: 20,
            bubbleText:
                "Si te va mas la onda retro, podés escribir el precio acá y te lo convierto en el momento, viejardo. 👴🏻",
            bubbleDirection: BubbleDirection.middlebottom,
          ),
        ],
      ),
    ];
  }

  // --- PASOS PARA CÁMARA ---
  static List<TargetFocus> cameraTargets({
    required GlobalKey keyROI,
    required GlobalKey keyManual,
    required GlobalKey keyEnteros,
    required GlobalKey keyHowie,
  }) {
    return [
      TargetFocus(
        identify: "cam_roi",
        keyTarget: keyROI,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.bottom,
            bubbleBottom: 225,
            bubbleText:
                "Enmarcar el precio con este cuadro para detectarlo automáticamente 🔍",
            bubbleDirection: BubbleDirection.top,
          ),
        ],
      ),
      TargetFocus(
        identify: "cam_manual",
        keyTarget: keyManual,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.left,
            bubbleText:
                "¿No lo toma? Usá el ingreso manual rápido sin salir de la cámara ✍️",
            bubbleDirection: BubbleDirection.right,
          ),
        ],
      ),
      TargetFocus(
        identify: "cam_enteros",
        keyTarget: keyEnteros,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.left,
            bubbleText:
                "Si la etiqueta tiene mucho 'ruido', activá el modo SOLO ENTEROS 🚫.00",
            bubbleDirection: BubbleDirection.right,
          ),
        ],
      ),
      TargetFocus(
        identify: "cam_howie",
        keyTarget: keyHowie,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.top,
            bubbleBottom: 20,
            bubbleText: "¡Intenta apuntar a un precio y observa la magia! ✨",
            bubbleDirection: BubbleDirection.middlebottom,
          ),
        ],
      ),
    ];
  }

  // --- PASOS PARA CARRITO ---
  static List<TargetFocus> cartTargets({required GlobalKey keyList}) {
    return [
      TargetFocus(
        identify: "cart_list",
        keyTarget: keyList,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        enableOverlayTab: true,
        contents: [
          howieAndBubbleDialog(
            align: ContentAlign.bottom,
            bubbleBottom: 225,
            bubbleText:
                "Acá tenés tu lista de compras con el total convertido. ¡Ya sabés cuánto vas a gastar! 🛍️",
            bubbleDirection: BubbleDirection.top,
          ),
        ],
      ),
    ];
  }
}
