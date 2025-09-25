import 'package:flutter/material.dart';
import 'dart:io';
import '../widget/wardrobe_page.dart';
import '../../../../shared/image_picker_helper.dart';
import '../../data/avatar_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  String? _avatarUrl;
  bool _isUploading = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final url = await AvatarService.getAvatar();
    if (mounted) {
      setState(() {
        _avatarUrl = url;
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    // Show remove option if either we have a selected image or an avatar URL
    final bool hasImage = _selectedImage != null || _avatarUrl != null;
    
    final File? result = await ImagePickerHelper.pickImage(
      context,
      currentImage: hasImage ? (_selectedImage ?? File('')) : null,
    );

    // Only process if user actually selected a new image or explicitly removed it
    if (result != null && result.path.isNotEmpty) {
      // User selected a new image
      setState(() {
        _selectedImage = result;
      });
      await _uploadAvatar(result);
    } else if (result == null && hasImage) {
      // User explicitly removed the image
      if (_avatarUrl != null) {
        await AvatarService.deleteAvatar(_avatarUrl!);
      }
      setState(() {
        _selectedImage = null;
        _avatarUrl = null;
      });
    }
    // If result is null and no image exists, user just cancelled - do nothing
  }

  Future<void> _uploadAvatar(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    final url = await AvatarService.uploadAvatar(imageFile);
    
    if (mounted) {
      setState(() {
        _avatarUrl = url;
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Stack(
                        children: [
                          if (_isLoading)
                            Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_avatarUrl != null)
                            Image.network(
                              _avatarUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/profile/default.png',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          else if (_selectedImage != null)
                            Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          else
                            Image.asset(
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
                          if (_isUploading)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
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
                    onPressed: _showImageSourceDialog,
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