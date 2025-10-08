import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/store_info_service.dart';

class StoreAccountPage extends StatefulWidget {
  const StoreAccountPage({super.key});

  @override
  State<StoreAccountPage> createState() => _StoreAccountPageState();
}

class _StoreAccountPageState extends State<StoreAccountPage> {
  String? logoUrl;
  File? _logoImage;
  bool isLoading = false;
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => isLoading = true);

    final storeData = await StoreService.getStore();
    if (storeData != null) {
      setState(() {
        storeNameController.text = storeData.storeName;
        storeAddressController.text = storeData.address;
        logoUrl = storeData.logoUrl;
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveChanges() async {
    setState(() => isLoading = true);

    final success = await StoreService.upsertStore(
      storeName: storeNameController.text.trim(),
      address: storeAddressController.text.trim(),
      logoUrl: logoUrl,
    );

    setState(() => isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('店家資訊已更新')),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失敗，請稍後再試')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
      
      // 上傳圖片
      await _uploadLogo();
    }
  }

  Future<void> _uploadLogo() async {
    if (_logoImage == null) return;
    
    setState(() => isLoading = true);
    
    // 上傳logo到storage
    final uploadedUrl = await StoreService.uploadLogo(_logoImage!);
    
    if (uploadedUrl != null) {
      // 更新店家資料
      final success = await StoreService.upsertStore(
        storeName: storeNameController.text.trim(),
        address: storeAddressController.text.trim(),
        logoUrl: uploadedUrl,
      );
      
      if (success) {
        setState(() {
          logoUrl = uploadedUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('店家Logo已更新')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('更新失敗，請稍後再試')),
          );
        }
      }
    }
    
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帳號設定'),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // 店家Logo
              Center(
                child: Column(
                  children: [
                    const Text(
                      '店家Logo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _logoImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.file(
                                  _logoImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.network(
                                      logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.store,
                                          size: 40,
                                          color: Colors.grey[600],
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '點擊上傳店家Logo',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 店家名稱
              TextField(
                controller: storeNameController,
                decoration: const InputDecoration(
                  labelText: '店家名稱',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // 店家地址
              TextField(
                controller: storeAddressController,
                decoration: const InputDecoration(
                  labelText: '店家地址',
                  border: OutlineInputBorder(),
                ),
              ),
                ],
                  ),
                ),
              ),
              // 儲存按鈕 - 貼齊底部
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '儲存',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}