import 'package:camera/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flappy_dash/bloc/game/game_cubit.dart';
import 'package:flappy_dash/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'component/flappy_dash_root_component.dart';

class FlappyDashGame extends FlameGame<FlappyDashWorld> with KeyboardEvents, HasCollisionDetection {
  FlappyDashGame(this.gameCubit)
      : super(
          world: FlappyDashWorld(),
          camera: CameraComponent.withFixedResolution(
            width: 600,
            height: 1000,
          ),
        );

  final GameCubit gameCubit;

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is KeyDownEvent;

    final isSpace = keysPressed.contains(LogicalKeyboardKey.space);

    if (isSpace && isKeyDown) {
      world.onSpaceDown();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class FlappyDashWorld extends World with TapCallbacks, HasGameRef<FlappyDashGame> {
  late FlappyDashRootComponent _rootComponent;

  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  bool _processing = false;
  bool _eyesClosed = false;

  Future<void> _initCamera() async {
    _cameraController = CameraController(cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front), ResolutionPreset.medium);

    await _cameraController.initialize();
    _cameraController.startImageStream(_processCameraImage);
  }

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

    final planeData = image.planes.map((plane) {
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
        _rootComponent.onSpaceDown();
        _eyesClosed = false;
      }
    }

    _processing = false;
  }

  @override
  void onLoad() {
    super.onLoad();
    _initCamera();
    _faceDetector = FaceDetector(options: FaceDetectorOptions(enableClassification: true, performanceMode: FaceDetectorMode.fast));
    add(
      FlameBlocProvider<GameCubit, GameState>(
        create: () => game.gameCubit,
        children: [
          _rootComponent = FlappyDashRootComponent(),
        ],
      ),
    );
  }

  void onSpaceDown() => _rootComponent.onSpaceDown();

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _rootComponent.onTapDown(event);
  }
}
