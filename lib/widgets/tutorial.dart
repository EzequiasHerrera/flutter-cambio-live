import 'package:flutter/material.dart';
import 'package:howmuch/widgets/action_button.dart';
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

    late TutorialCoachMark tutorial;

    tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      focusAnimationDuration: const Duration(milliseconds: 800),
      unFocusAnimationDuration: const Duration(milliseconds: 600),
      pulseEnable: false,

      skipWidget: Padding(
        padding: const EdgeInsets.only(top: 12.0, right: 16.0),
        child: ActionButton(
          label: "Omitir",
          icon: Icons.skip_next_rounded,
          isPrimary:
              true, // Secundario para que no compita visualmente con Howie
          width: 150, // Ancho acotado para el botón flotante
          onPressed: () {
            tutorial.skip();
          },
        ),
      ),

      onFinish: onFinish,
      onSkip: () {
        onFinish?.call();
        return true;
      },
    );

    tutorial.show(context: context);
  }

  static TargetContent howieAndBubbleDialog({
    ContentAlign align = ContentAlign.top,
    bool animation = false,
    required String bubbleText,
    BubbleDirection bubbleDirection = BubbleDirection.bottom,
    double howieSize = 160,
    double howieAngle = 0,
    Alignment howieAlignment = Alignment.center,
    Offset howieOffsetRatio = Offset.zero,
    Offset bubbleOffsetRatio = Offset.zero,
  }) {
    return TargetContent(
      align: align,
      child: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Transform.translate(
                    offset: Offset(
                      size.width * bubbleOffsetRatio.dx,
                      size.height * bubbleOffsetRatio.dy,
                    ),
                    child: BubbleDialog(
                      message: bubbleText,
                      direction: bubbleDirection,
                    ),
                  ),
                ),
                if (howieSize > 0)
                  Align(
                    alignment: howieAlignment,
                    child: Transform.translate(
                      offset: Offset(
                        size.width * howieOffsetRatio.dx,
                        size.height * howieOffsetRatio.dy,
                      ),
                      child: Transform.rotate(
                        angle: howieAngle * (3.1416 / 180),
                        child: SizedBox(
                          height: howieSize.clamp(100.0, size.height * 0.4),
                          child: animation
                              ? const SizedBox.shrink()
                              : const HowieGreetings(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
            howieAlignment: Alignment.center,
            howieSize: 180,
            bubbleText:
                "¡Bienvenido a Howmuch! Soy Howie, te voy a mostrar el lugar. Preparado? 🧡✈️",
            bubbleDirection: BubbleDirection.middlebottom,
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
            howieAlignment: Alignment.bottomLeft,
            howieOffsetRatio: const Offset(-0.18, 0.18),
            howieAngle: 45,
            howieSize: 160,
            bubbleText:
                "Elegí la moneda origen y a la que querés convertir 💱🪙",
            bubbleDirection: BubbleDirection.bottomLeft,
            bubbleOffsetRatio: Offset(0.0, 0.2),
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
            howieAlignment: Alignment.bottomCenter,
            howieSize: 160,
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
            howieAlignment: Alignment.bottomCenter,
            howieSize: 160,
            bubbleText:
                "Este es el navegador hacia el conversor manual 💱, tu carrito de compras 🛒 o directo a la cámara 📷",
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
            howieAlignment: Alignment.bottomCenter,
            howieOffsetRatio: Offset(0.0, 0.05),
            howieSize: 160,
            bubbleText:
                "Hola viejardo! Te sentís mas a gusto acá? Es todo tuyo 👴🏻",
            bubbleDirection: BubbleDirection.middlebottom,
            bubbleOffsetRatio: Offset(0.0, 0.05),
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
            align: ContentAlign.top,
            howieSize: 160, // Si no se necesita a Howie en este paso
            howieOffsetRatio: Offset(-0.45, 0.1),
            howieAngle: 50,
            bubbleText:
                "Colocá el precio dentro del recuadro para detectarlo automáticamente 🔍",
            bubbleDirection: BubbleDirection.bottomLeft,
            bubbleOffsetRatio: Offset(0.0, 0.15),
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
            howieSize: 160,
            bubbleText:
                "Si hay problemas, siempre podés ingresarlo manualmente! ✍️",
            bubbleDirection: BubbleDirection.middlebottom,
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
            howieSize: 160,
            bubbleText:
                "Querés un número redondo? Utiliza el modo SOLO ENTEROS ✅",
            bubbleDirection: BubbleDirection.middlebottom,
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
            howieAlignment: Alignment.center,
            howieSize: 160,
            bubbleText: "¡Intentá apuntar a un precio y observa la magia! ✨📷",
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
            align: ContentAlign.top,
            howieSize: 300,
            howieAngle: 160,
            howieOffsetRatio: Offset(0.0, 0.04),
            bubbleText:
                "Acá tenés tu lista de compras con el total convertido. ¡Ya sabés cuánto vas a gastar! 🛍️",
            bubbleDirection: BubbleDirection.top,
            bubbleOffsetRatio: Offset(0.0, 0.55),
          ),
        ],
      ),
    ];
  }
}
