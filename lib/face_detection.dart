/*import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetection {


 void _processCameraImage(CameraImage image) async {
    if (_processing) return;
    _processing = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front);
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final planeData =
        image.planes.map((plane) {
          return InputImageMetadata(size: imageSize, rotation: imageRotation, format: inputImageFormat, bytesPerRow: plane.bytesPerRow);
        }).toList();

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: planeData.isNotEmpty ? planeData.first.bytesPerRow : 0,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final face = faces.first;
      final left = face.leftEyeOpenProbability ?? 1.0;
      final right = face.rightEyeOpenProbability ?? 1.0;

      if (!_eyesClosed && left < 0.3 && right < 0.3) {
        _eyesClosed = true;
      }

      if (_eyesClosed && left > 0.8 && right > 0.8) {
        print('ok');
        _eyesClosed = false;
      }
    }

    _processing = false;
  }

}*/