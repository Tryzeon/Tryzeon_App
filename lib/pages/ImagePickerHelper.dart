import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // 若你要使用 File 顯示圖片

class ImagePickerHelper {
  static Future<File?> pickImage(BuildContext context) async {
    File? selectedImage;

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('使用相機拍照'),
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    selectedImage = File(pickedFile.path);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('從相簿選擇'),
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    selectedImage = File(pickedFile.path);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );

    return selectedImage;
  }
}