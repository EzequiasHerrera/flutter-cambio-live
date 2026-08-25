import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _avanzarAnimacion() async {
    if (_composition == null || _controller.isAnimating) return;

    widget.onTap?.call();

    final double totalFrames = _composition!.endFrame;
    if (totalFrames == 0) return;

    if (_paso == 0) {
      // FRAME 0 → FRAME 26
      const double frameInicio = 0.0;
      const double frameFinal = 26.0;
      final double framesATransicionar = frameFinal - frameInicio;

      // Duración proporcional precisa basada en la duración REAL del asset
      final Duration duracion = _composition!.duration * (framesATransicionar / totalFrames);

      setState(() => _paso = 1);

      await _controller.animateTo(
        frameFinal / totalFrames,
        duration: duracion,
        curve: Curves.linear,
      );
      return;
    }

    if (_paso == 1) {
      // FRAME 26 → FRAME 31
      const double frameInicio = 26.0;
      const double frameFinal = 31.0;
      final double framesATransicionar = frameFinal - frameInicio;

      final Duration duracion = _composition!.duration * (framesATransicionar / totalFrames);

      await _controller.animateTo(
        frameFinal / totalFrames,
        duration: duracion,
        curve: Curves.easeOut,
      );

      // Reset al estado inicial
      _controller.value = 0.0;

      if (mounted) {
        setState(() => _paso = 0);
      }
    }
  }

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
          _controller.duration = composition.duration;
          _controller.value = 0.0;
        },
      ),
    );
  }
}