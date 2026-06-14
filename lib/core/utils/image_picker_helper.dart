import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(
    final BuildContext context, {
    final double maxWidth = 1080,
    final double maxHeight = 1920,
    final int imageQuality = 85,
    final bool enableCrop = false,
    final CropStyle cropStyle = CropStyle.rectangle,
    final List<CropAspectRatioPreset>? aspectRatioPresets,
    final String? hint,
    final String title = '選擇圖片來源',
  }) async {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    ImageSource? source;
    await showAppActionSheet(
      context,
      title: title,
      hint: hint,
      actions: [
        AppMenuAction(
          icon: Icons.photo_library,
          title: '從相簿選擇',
          onTap: () => source = ImageSource.gallery,
        ),
        AppMenuAction(
          icon: Icons.camera_alt,
          title: '拍攝新照片',
          onTap: () => source = ImageSource.camera,
        ),
      ],
    );

    if (source == null) return null;
    final ImageSource selectedSource = source!;

    try {
      final XFile? pickedFile = await _picker.pickImage(source: selectedSource);
      if (pickedFile == null) return null;

      String sourcePath = pickedFile.path;

      if (enableCrop) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: sourcePath,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '編輯圖片',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: primaryColor,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              cropStyle: cropStyle,
              aspectRatioPresets:
                  aspectRatioPresets ??
                  [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
            ),
            IOSUiSettings(
              title: '編輯圖片',
              cropStyle: cropStyle,
              aspectRatioPresets:
                  aspectRatioPresets ??
                  [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
            ),
          ],
        );

        if (croppedFile == null) return null;
        sourcePath = croppedFile.path;
      }

      // Generate timestamp based filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = '$timestamp.jpg';

      // Get temp dir
      final Directory directory = await getTemporaryDirectory();
      final String newPath = '${directory.path}/$newFileName';

      // Compress and convert to JPG
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        newPath,
        quality: imageQuality,
        format: CompressFormat.jpeg,
        minWidth: maxWidth.toInt(),
        minHeight: maxHeight.toInt(),
      );

      if (compressedFile == null) return null;
      return File(compressedFile.path);
    } catch (e, stackTrace) {
      AppLogger.error('Pick image failed', e, stackTrace);
      if (context.mounted) {
        TopNotification.show(context, message: '選擇圖片失敗，請稍後再試');
      }
    }

    return null;
  }

  static Future<List<File>?> pickImages(
    final BuildContext context, {
    final int maxImages = 3,
    final double maxWidth = 1080,
    final double maxHeight = 1920,
    final int imageQuality = 85,
  }) async {
    try {
      if (maxImages <= 0) return null;

      // The pickMultiImage method enforces a limit >= 2.
      // If we only need 1 image, fallback to pickImage single selection.
      if (maxImages == 1) {
        final File? singleFile = await pickImage(
          context,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          enableCrop: false,
        );
        return singleFile != null ? [singleFile] : null;
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage(limit: maxImages);

      if (pickedFiles.isEmpty) return null;

      final List<XFile> limitedFiles = pickedFiles.length > maxImages
          ? pickedFiles.sublist(0, maxImages)
          : pickedFiles;

      final List<File> processedFiles = [];

      for (final pickedFile in limitedFiles) {
        final String sourcePath = pickedFile.path;
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String newFileName = '${timestamp}_${processedFiles.length}.jpg';
        final Directory directory = await getTemporaryDirectory();
        final String newPath = '${directory.path}/$newFileName';

        final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
          sourcePath,
          newPath,
          quality: imageQuality,
          format: CompressFormat.jpeg,
          minWidth: maxWidth.toInt(),
          minHeight: maxHeight.toInt(),
        );

        if (compressedFile != null) {
          processedFiles.add(File(compressedFile.path));
        }
      }

      if (processedFiles.isEmpty) return null;
      return processedFiles;
    } catch (e, stackTrace) {
      AppLogger.error('Pick images failed', e, stackTrace);
      if (context.mounted) {
        TopNotification.show(context, message: '選擇圖片失敗，請稍後再試');
      }
      return null;
    }
  }
}
