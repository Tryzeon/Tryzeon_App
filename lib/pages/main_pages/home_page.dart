import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraReady = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  //拍照
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      
      // 尋找前置鏡頭，如果沒有則使用第一個可用的鏡頭
      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );
      
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      print('相機初始化失敗: $e');
      // 處理錯誤，例如顯示錯誤訊息
    }
  }

  //錄影
  Future<void> _toggleRecording() async {
    if (!_controller.value.isInitialized) {
      print("Camera not initialized");
      return;
    }

    if (_isRecording) {
      final videoFile = await _controller.stopVideoRecording();
      setState(() => _isRecording = false);
      print('錄影結束，儲存於：${videoFile.path}');
    } else {
      await _controller.startVideoRecording(); // 不回傳 XFile
      setState(() => _isRecording = true);
      print('開始錄影');
    }

  }


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _controller.value.isTakingPicture) return;
    final image = await _controller.takePicture();
    // 你可以在這裡儲存或預覽照片
    print('照片儲存於：${image.path}');
  }

  Future<CameraController> createCameraController({
    required CameraLensDirection direction,
    ResolutionPreset preset = ResolutionPreset.high,
  }) async {
    final cameras = await availableCameras();
    final selectedCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == direction,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selectedCamera,
      preset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return _isCameraReady
        ? Stack(
      children: [
        //相機預覽畫面
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 9/16,  //鎖死比例
              child: CameraPreview(_controller),
            ),
          ),
        ),
        // 虛擬衣櫃按鈕
        Positioned(
          top: MediaQuery.of(context).size.height * 0.125,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: IconButton(
                onPressed: () {
                  // TODO: Navigate to closet page
                },
                icon: Icon(
                  Icons.checkroom,
                  size: 32,
                  color: Colors.brown.withOpacity(0.6),
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ),
          ),
        ),

        //錄影與照相按鈕
        Positioned(
          bottom: 30, // 調整高低
          left: 32,
          right: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FloatingActionButton(
                onPressed: _toggleRecording,
                backgroundColor: _isRecording ? Colors.redAccent : Colors.blueAccent,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
              FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: Colors.pinkAccent,
                child: const Icon(Icons.camera_alt),
              ),
            ],
          ),
        ),
      ],
    )
        : const Center(child: CircularProgressIndicator());
  }
}