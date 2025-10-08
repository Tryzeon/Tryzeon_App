import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/store_info_service.dart';
import '../../../../login/persentation/pages/login_page.dart';
import 'package:tryzeon/shared/services/logout_service.dart';

class StoreAccountPage extends StatefulWidget {
  const StoreAccountPage({super.key});

  @override
  State<StoreAccountPage> createState() => _StoreAccountPageState();
}

class _StoreAccountPageState extends State<StoreAccountPage> {
  String storeName = '我的店家';
  String address = '台南市東區中華東路一段123號';
  String? logoUrl;
  File? _logoImage;
  bool isEditingName = false;
  bool isEditingAddress = false;
  bool isLoading = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
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
        storeName = storeData.storeName;
        address = storeData.address;
        logoUrl = storeData.logoUrl;
        nameController.text = storeName;
        addressController.text = address;
      });
    }
    
    setState(() => isLoading = false);
  }

  void _toggleEditName() async {
    if (isEditingName) {
      final newName = nameController.text.trim();
      if (newName.isNotEmpty && newName != storeName) {
        setState(() => isLoading = true);
        
        final success = await StoreService.upsertStore(
          storeName: newName,
          address: address,
          logoUrl: logoUrl,
        );
        
        if (success) {
          setState(() {
            storeName = newName;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('店家名稱已更新')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('更新失敗，請稍後再試')),
            );
          }
          nameController.text = storeName;
        }
        
        setState(() => isLoading = false);
      }
    } else {
      nameController.text = storeName;
    }
    
    setState(() {
      isEditingName = !isEditingName;
    });
  }

  void _toggleEditAddress() async {
    if (isEditingAddress) {
      final newAddress = addressController.text.trim();
      if (newAddress.isNotEmpty && newAddress != address) {
        setState(() => isLoading = true);
        
        final success = await StoreService.upsertStore(
          storeName: storeName,
          address: newAddress,
          logoUrl: logoUrl,
        );
        
        if (success) {
          setState(() {
            address = newAddress;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('店家地址已更新')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('更新失敗，請稍後再試')),
            );
          }
          addressController.text = address;
        }
        
        setState(() => isLoading = false);
      }
    } else {
      addressController.text = address;
    }
    
    setState(() {
      isEditingAddress = !isEditingAddress;
    });
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
        storeName: storeName,
        address: address,
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

  Future<void> _signOut() async {
    // 顯示確認對話框
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認登出'),
          content: const Text('你確定要登出齁?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('確定，但我會記得回來'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      await LogoutService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
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
              Row(
                children: [
                  Expanded(
                    child: isEditingName
                        ? TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: '店家名稱',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '店家名稱',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                storeName,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                  ),
                  IconButton(
                    icon: Icon(isEditingName ? Icons.check : Icons.edit),
                    onPressed: _toggleEditName,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 店家地址
              Row(
                children: [
                  Expanded(
                    child: isEditingAddress
                        ? TextField(
                            controller: addressController,
                            decoration: const InputDecoration(
                              labelText: '店家地址',
                              border: OutlineInputBorder(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '店家地址',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                  ),
                  IconButton(
                    icon: Icon(isEditingAddress ? Icons.check : Icons.edit),
                    onPressed: _toggleEditAddress,
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
          // 登出按鈕 - 貼齊底部
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '登出',
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