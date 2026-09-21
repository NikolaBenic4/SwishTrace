import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'court_preview.dart';

typedef CameraImageHandler =
    Future<void> Function(CameraImage image, int rotationDegrees);

class SessionCameraPreview extends StatefulWidget {
  const SessionCameraPreview({
    required this.onImageAvailable,
    required this.streamImages,
    super.key,
  });

  final CameraImageHandler onImageAvailable;
  final bool streamImages;

  @override
  State<SessionCameraPreview> createState() => _SessionCameraPreviewState();
}

class _SessionCameraPreviewState extends State<SessionCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeCameraFuture;
  CameraDescription? _selectedCamera;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraFuture = _prepareCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      final camera = _selectedCamera;
      if (camera != null) {
        _initializeCameraFuture = _initializeController(camera);
        setState(() {});
      }
    }
  }

  Future<void> _prepareCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No camera found');
        return;
      }

      CameraDescription? backCamera;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
          break;
        }
      }

      _selectedCamera = backCamera ?? cameras.first;
      await _initializeController(_selectedCamera!);
    } on CameraException catch (error) {
      setState(() => _errorMessage = _messageForCameraError(error));
    } catch (_) {
      setState(() => _errorMessage = 'Camera unavailable');
    }
  }

  Future<void> _initializeController(CameraDescription camera) async {
    await _controller?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _controller = controller;
    await controller.initialize();
    await _updateImageStream();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() => _errorMessage = null);
  }

  @override
  void didUpdateWidget(covariant SessionCameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamImages != widget.streamImages) {
      _updateImageStream();
    }
  }

  Future<void> _updateImageStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (widget.streamImages && !controller.value.isStreamingImages) {
      await controller.startImageStream((image) {
        widget.onImageAvailable(image, _imageRotationDegrees(controller));
      });
    } else if (!widget.streamImages && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  int _imageRotationDegrees(CameraController controller) {
    final deviceDegrees = switch (controller.value.deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
    final sensorDegrees = _selectedCamera?.sensorOrientation ?? 0;
    final isFrontFacing =
        _selectedCamera?.lensDirection == CameraLensDirection.front;

    return isFrontFacing
        ? (sensorDegrees + deviceDegrees) % 360
        : (sensorDegrees - deviceDegrees + 360) % 360;
  }

  String _messageForCameraError(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' => 'Camera permission needed',
      'CameraAccessRestricted' => 'Camera access restricted',
      _ => 'Camera unavailable',
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeCameraFuture,
      builder: (context, snapshot) {
        final controller = _controller;
        final isReady = controller != null && controller.value.isInitialized;

        if (isReady) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final previewSize = controller.value.previewSize;
              final isLandscape = constraints.maxWidth >= constraints.maxHeight;
              final previewWidth = isLandscape
                  ? previewSize?.width
                  : previewSize?.height;
              final previewHeight = isLandscape
                  ? previewSize?.height
                  : previewSize?.width;

              return ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewWidth ?? 1,
                    height: previewHeight ?? 1,
                    child: CameraPreview(controller),
                  ),
                ),
              );
            },
          );
        }

        return _CameraFallback(
          message:
              _errorMessage ??
              (snapshot.connectionState == ConnectionState.waiting
                  ? 'Starting camera'
                  : 'Camera preview'),
        );
      },
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CourtPreview(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
