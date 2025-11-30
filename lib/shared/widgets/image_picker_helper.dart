import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(
    final BuildContext context, {
    final File? currentImage,
    final double maxWidth = 1080,
    final double maxHeight = 1920,
    final int imageQuality = 85,
    final String title = '選擇圖片來源',
    final String galleryText = '從相簿選擇',
    final String cameraText = '拍攝新照片',
    final Color iconColor = Colors.brown,
  }) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
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
          TopNotification.show(
            context,
            message: '選擇圖片失敗: $e',
            type: NotificationType.error,
          );
        }
      }
    }

    // User cancelled or no image selected
    return currentImage;
  }
}
