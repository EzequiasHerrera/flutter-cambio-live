import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/feedback_service.dart';

class HowieBarriendo extends StatefulWidget {
  final VoidCallback? onTap;
  const HowieBarriendo({super.key, this.onTap});

  @override
  State<HowieBarriendo> createState() => _HowieState();
}

class _HowieState extends State<HowieBarriendo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int _paso = 0;

  LottieComposition? _composition;

  // ============================================================
  // VELOCIDAD
  // ============================================================

  final double factorVelocidad = 0.05;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // CALCULAR DURACIÓN DE UN TRAMO
  // ============================================================

  Duration _calcularDuracionTramo(
      double framesATransicionar,
      double totalFrames,
      ) {
    if (_composition == null) {
      return Duration.zero;
    }

    final double proporcion =
        framesATransicionar / totalFrames;

    final int msBase =
        _composition!.duration.inMilliseconds;

    final int msCalculados =
    ((msBase * proporcion) / factorVelocidad).round();

    return Duration(
      milliseconds: msCalculados,
    );
  }

  // ============================================================
  // ANIMACIÓN
  // ============================================================

  Future<void> _avanzarAnimacion() async {
    if (_composition == null) {
      return;
    }

    // Evita otro tap mientras está reproduciendo.
    if (_controller.isAnimating) {
      return;
    }

    // Llamamos al callback si existe
    widget.onTap?.call();

    final double totalFrames =
        _composition!.endFrame;

    // ==========================================================
    // PASO 0
    //
    // Primer tap:
    //
    // FRAME 0 → FRAME 26
    // ==========================================================

    if (_paso == 0) {
      const double frameInicio = 0.0;
      const double frameFinal = 26.0;

      final double framesATransicionar =
          frameFinal - frameInicio;

      final Duration duracion =
      _calcularDuracionTramo(
        framesATransicionar,
        totalFrames,
      );

      setState(() {
        _paso = 1;
      });

      await _controller.animateTo(
        frameFinal / totalFrames,
        duration: duracion,
        curve: Curves.linear,
      );

      return;
    }

    // ==========================================================
    // PASO 1
    //
    // Segundo tap:
    //
    // FRAME 26 → FRAME 31
    //
    // Usamos EASE OUT:
    //
    // empieza normal
    // ↓
    // desacelera
    // ↓
    // llega suavemente al final
    //
    // Sin overshoot / rebote.
    // ==========================================================

    if (_paso == 1) {
      const double frameInicio = 26.0;
      const double frameFinal = 31.0;

      final double framesATransicionar =
          frameFinal - frameInicio;

      final Duration duracion =
      _calcularDuracionTramo(
        framesATransicionar,
        totalFrames,
      );

      await _controller.animateTo(
        frameFinal / totalFrames,
        duration: duracion,
        curve: Curves.easeOut,
      );

      // ========================================================
      // VOLVER AL ESTADO INICIAL
      // ========================================================

      _controller.value = 0.0;

      if (mounted) {
        setState(() {
          _paso = 0;
        });
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _avanzarAnimacion,
      child: Lottie.asset(
        'assets/animations/Howie_Barriendo.json',
        controller: _controller,
        fit: BoxFit.cover,
        onLoaded: (composition) {
          _composition = composition;

          _controller.duration =
              composition.duration;

          // Estado inicial.
          _controller.value = 0.0;
        },
      ),
    );
  }
}