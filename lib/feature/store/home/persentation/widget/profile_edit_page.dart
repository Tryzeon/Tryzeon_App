import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StoreAccountPage extends StatefulWidget {
  const StoreAccountPage({super.key});

  @override
  State<StoreAccountPage> createState() => _StoreAccountPageState();
}

class _StoreAccountPageState extends State<StoreAccountPage> {
  String storeName = '我的店家';
  String address = '台南市東區中華東路一段123號';
  File? _logoImage;
  bool isEditingName = false;
  bool isEditingAddress = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _toggleEditName() {
    setState(() {
      if (isEditingName) {
        storeName = nameController.text.trim();
      } else {
        nameController.text = storeName;
      }
      isEditingName = !isEditingName;
    });
  }

  void _toggleEditAddress() {
    setState(() {
      if (isEditingAddress) {
        address = addressController.text.trim();
      } else {
        addressController.text = address;
      }
      isEditingAddress = !isEditingAddress;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
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
    );
  }
}