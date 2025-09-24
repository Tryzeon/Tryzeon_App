import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../components/wardrobe/wardrobe_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('沒有可用的相機')),
          );
        }
        return;
      }
      
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('相機初始化失敗: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _controller!.takePicture();
      
      if (mounted) {
        // TODO: 處理拍攝的照片
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('照片已儲存: ${image.path}')),
        );
        
        // 關閉相機
        _closeCamera();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失敗: $e')),
        );
      }
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _closeCamera() {
    _controller?.dispose();
    setState(() {
      _controller = null;
      _isCameraReady = false;
    });
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '選擇圖片來源',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.brown),
                  title: const Text('從相簿選擇'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.brown),
                  title: const Text('拍攝新照片'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('移除圖片'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('圖片已更新')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選擇圖片失敗: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraReady && _controller != null) {
      // 相機視圖
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: _closeCamera,
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: _isCapturing ? null : _takePicture,
                  backgroundColor: Colors.white,
                  child: _isCapturing
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Icon(Icons.camera_alt, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 主頁面視圖
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 標題
              const Text(
                '虛擬試衣間',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 40),
              
              // 虛擬人偶
              Expanded(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/profile/default.png',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 按鈕區域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 衣櫃按鈕
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WardrobePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.checkroom),
                    label: const Text('我的衣櫃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  
                  // 虛擬試穿按鈕
                  ElevatedButton.icon(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('虛擬試穿'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}