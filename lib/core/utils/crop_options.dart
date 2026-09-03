import 'package:image_cropper/image_cropper.dart';

/// Crop settings. Passing null to `ImagePickerHelper.pickImage` means no crop.
sealed class CropOptions {
  const CropOptions({this.title = '編輯圖片', this.style = CropStyle.rectangle});

  final String title;
  final CropStyle style;
}

class LockedCrop extends CropOptions {
  const LockedCrop({required this.ratio, super.title, super.style});

  final ({int x, int y}) ratio;
}

class FreeCrop extends CropOptions {
  const FreeCrop({this.presets, super.title, super.style});

  final List<CropAspectRatioPreset>? presets;
}
