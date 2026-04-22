import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraService {
  CameraController? controller;
  bool isInitialized = false;

  Future<void> initialize(void Function(InputImage) onInputImage) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
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

      await controller!.startImageStream((CameraImage image) {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) onInputImage(inputImage);
      });

      isInitialized = true;
    } catch (e) {
      debugPrint("Error cámara: $e");
    }
  }

  void dispose() {
    if (isInitialized) controller?.stopImageStream();
    controller?.dispose();
    isInitialized = false;
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

      final Uint8List cleanYPlane = Uint8List(width * height);
      for (int y = 0; y < height; y++) {
        cleanYPlane.setRange(
          y * width,
          (y + 1) * width,
          bytes.getRange(y * bytesPerRow, y * bytesPerRow + width),
        );
      }

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
