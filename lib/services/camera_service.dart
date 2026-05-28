import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraService {
  CameraController? controller;
  bool isInitialized = false;

  // Compuerta lógica para controlar los FPS y evitar saturación de memoria
  bool _isProcessingFrame = false;

  Future<void> initialize(void Function(InputImage) onInputImage) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    controller = CameraController(
      cameras.first,
      ResolutionPreset.ultraHigh,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller!.initialize();

      try {
        await controller!.setFocusMode(FocusMode.auto);
      } catch (_) {}

      await controller!.startImageStream((CameraImage image) async {
        // Si el pipeline sigue ocupado con el frame anterior, se descarta el actual
        if (_isProcessingFrame) return;

        try {
          _isProcessingFrame = true; // Cierra la compuerta

          final inputImage = _inputImageFromCameraImage(image);
          if (inputImage != null) {
            //------💡LLAMAMOS A onFrame------💡
            onInputImage(inputImage);
          }
        } catch (e) {
          debugPrint("Error procesando frame en stream: $e");
        } finally {
          _isProcessingFrame =
              false; // Abre la compuerta para el siguiente frame disponible
        }
      });

      isInitialized = true;
    } catch (e) {
      debugPrint("Error cámara: $e");
    }
  }

  Future<void> dispose() async {
    if (controller != null) {
      if (isInitialized) {
        await controller!.stopImageStream();
      }
      await controller!.dispose();
      controller = null; // IMPORTANTE: Anular para evitar errores de referencia
    }
    isInitialized = false;
    _isProcessingFrame = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (controller == null) return null;
    try {
      final camera = controller!.description;
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation90deg;

      final plane = image.planes[0];
      final bytes = plane.bytes;
      final width = image.width;
      final height = image.height;
      final bytesPerRow = plane.bytesPerRow;

      // Asignación exacta del plano de luminancia Y sin el padding de memoria
      final Uint8List cleanYPlane = Uint8List(width * height);

      for (int y = 0; y < height; y++) {
        // Sincroniza el inicio de la fila en memoria considerando el bytesPerRow real
        final int sourceStart = y * bytesPerRow;
        final int targetStart = y * width;

        // Copia únicamente los bytes útiles (width), ignorando los bytes de padding
        cleanYPlane.setRange(
          targetStart,
          targetStart + width,
          bytes.getRange(sourceStart, sourceStart + width),
        );
      }

      // Construcción del plano NV21 estándar para ML Kit
      final Uint8List nv21Bytes = Uint8List(width * height * 3 ~/ 2);
      nv21Bytes.setRange(0, width * height, cleanYPlane);
      nv21Bytes.fillRange(width * height, nv21Bytes.length, 128);

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
