import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraService {
  CameraController? controller;
  bool isInitialized = false;

  /// Flag to prevent concurrent frame processing.
  bool _isProcessingFrame = false;

  /// Initializes the camera and starts the image stream.
  /// [onInputImage] is called for each processed frame.
  Future<void> initialize(void Function(InputImage) onInputImage) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No cameras found.");
        return;
      }

      controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await controller!.initialize();

      // Try to enable autofocus if supported
      try {
        await controller!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint("Autofocus not supported: $e");
      }

      await controller!.startImageStream((CameraImage image) {
        if (_isProcessingFrame) return;

        _isProcessingFrame = true;
        try {
          final inputImage = _inputImageFromCameraImage(image);
          if (inputImage != null) {
            onInputImage(inputImage);
          }
        } catch (e) {
          debugPrint("Error processing frame: $e");
        } finally {
          _isProcessingFrame = false;
        }
      });

      isInitialized = true;
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      isInitialized = false;
    }
  }

  /// Stops the stream and disposes of the controller.
  Future<void> dispose() async {
    if (controller != null) {
      if (isInitialized) {
        await controller!.stopImageStream();
      }
      await controller!.dispose();
      controller = null;
    }
    isInitialized = false;
    _isProcessingFrame = false;
  }

  /// Converts a [CameraImage] to an [InputImage] compatible with ML Kit.
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (controller == null) return null;

    try {
      final camera = controller!.description;
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation90deg;

      final plane = image.planes[0];
      final bytes = plane.bytes;
      final width = image.width;
      final height = image.height;
      final bytesPerRow = plane.bytesPerRow;

      // Extract clean Y plane (Luminance) removing memory padding
      final Uint8List cleanYPlane = Uint8List(width * height);
      for (int y = 0; y < height; y++) {
        cleanYPlane.setRange(
          y * width,
          y * width + width,
          bytes.getRange(y * bytesPerRow, y * bytesPerRow + width),
        );
      }

      // Construct NV21 bytes (Y + dummy UV)
      final Uint8List nv21Bytes = Uint8List(width * height * 3 ~/ 2);
      nv21Bytes.setRange(0, width * height, cleanYPlane);
      nv21Bytes.fillRange(width * height, nv21Bytes.length, 128); // Neutral chrominance

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
      debugPrint("Conversion error: $e");
      return null;
    }
  }
}

