import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(
    final BuildContext context, {
    final double maxWidth = 1080,
    final double maxHeight = 1920,
    final int imageQuality = 85,
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
                const Text(
                  '選擇圖片來源',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('從相簿選擇'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('拍攝新照片'),
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
          // Generate timestamp based filename
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String newFileName = '$timestamp.jpg';

          // Get temp dir
          final Directory directory = await getTemporaryDirectory();
          final String newPath = '${directory.path}/$newFileName';

          // Compress and convert to JPG
          final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
            pickedFile.path,
            newPath,
            quality: imageQuality,
            format: CompressFormat.jpeg,
            minWidth: maxWidth.toInt(),
            minHeight: maxHeight.toInt(),
          );

          if (compressedFile != null) {
            return File(compressedFile.path);
          }
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
    return null;
  }
}
