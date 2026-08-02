import 'package:image_cropper/image_cropper.dart';

/// 裁切設定。傳 null 給 `ImagePickerHelper.pickImage` 代表不裁切。
sealed class CropOptions {
  const CropOptions({this.title = '編輯圖片', this.style = CropStyle.rectangle});

  final String title;
  final CropStyle style;
}

/// 裁切框鎖死在固定比例，使用者只能拖曳與縮放。
class LockedCrop extends CropOptions {
  const LockedCrop({required this.ratio, super.title, super.style});

  final ({int x, int y}) ratio;
}

/// 裁切框可自由調整，並提供比例選單。
class FreeCrop extends CropOptions {
  const FreeCrop({this.presets, super.title, super.style});

  final List<CropAspectRatioPreset>? presets;
}
