import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArPracticeScreen extends StatefulWidget {
  const ArPracticeScreen({super.key, required this.scoreDocumentPath});

  final String scoreDocumentPath;

  @override
  State<ArPracticeScreen> createState() {
    return ArPracticeScreenState();
  }
}

class ArPracticeScreenState extends State<ArPracticeScreen> {
  CameraController? cameraController;
  String? cameraError;
  bool isProcessingCameraImage = false;
  DateTime? lastCameraImageTime;

  final Duration cameraImageInterval = const Duration(milliseconds: 225);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: buildCameraContent()),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  tooltip: 'Back',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCameraContent() {
    CameraController? currentCameraController = cameraController;

    if (cameraError != null) {
      return Center(
        child: Text(
          cameraError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (currentCameraController == null ||
        !currentCameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(currentCameraController);
  }

  void processCameraImage(CameraImage cameraImage) {
    if (isProcessingCameraImage) {
      return;
    }

    DateTime currentTime = DateTime.now();

    if (lastCameraImageTime != null) {
      Duration timeSinceLastImage = currentTime.difference(
        lastCameraImageTime!,
      );

      if (timeSinceLastImage < cameraImageInterval) {
        return;
      }
    }

    lastCameraImageTime = currentTime;
    isProcessingCameraImage = true;

    try {
      // OpenCV keyboard detection will be added here next.
    } finally {
      isProcessingCameraImage = false;
    }
  }

  Future<void> initializeCamera() async {
    CameraController? newCameraController;

    try {
      List<CameraDescription> cameras = await availableCameras();
      CameraDescription? rearCamera;

      for (CameraDescription camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }

      if (rearCamera == null) {
        if (mounted) {
          setState(() {
            cameraError = 'No rear camera is available on this device.';
          });
        }

        return;
      }

      newCameraController = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await newCameraController.initialize();

      if (!mounted) {
        await newCameraController.dispose();
        return;
      }

      await newCameraController.startImageStream(processCameraImage);

      if (!mounted) {
        await newCameraController.dispose();
        return;
      }

      setState(() {
        cameraController = newCameraController;
      });
    } on CameraException catch (error) {
      await newCameraController?.dispose();

      if (mounted) {
        setState(() {
          cameraError = error.description ?? 'The camera could not be opened.';
        });
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    cameraController?.dispose();

    super.dispose();
  }
}
