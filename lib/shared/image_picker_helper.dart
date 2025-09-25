import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(
    BuildContext context, {
    File? currentImage,
    double maxWidth = 1080,
    double maxHeight = 1920,
    int imageQuality = 85,
    String title = '選擇圖片來源',
    String galleryText = '從相簿選擇',
    String cameraText = '拍攝新照片',
    String removeText = '移除圖片',
    Color iconColor = Colors.brown,
  }) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource?>(
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_library, color: iconColor),
                  title: Text(galleryText),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: iconColor),
                  title: Text(cameraText),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                if (currentImage != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: iconColor),
                    title: Text(removeText),
                    onTap: () => Navigator.pop(context, null),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null && currentImage != null) {
      // User selected remove
      return null;
    } else if (source != null) {
      // User selected gallery or camera
      try {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
        
        if (pickedFile != null) {
          return File(pickedFile.path);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('選擇圖片失敗: $e')),
          );
        }
      }
    }
    
    // User cancelled or no image selected
    return currentImage;
  }
}