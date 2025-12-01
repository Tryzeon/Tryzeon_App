import 'dart:io';

import 'package:tryzeon/feature/personal/personal/data/wardrobe_service.dart';
import 'package:tryzeon/shared/models/result.dart';

class WardrobeItemType {
  const WardrobeItemType({required this.zh, required this.en});
  final String zh;
  final String en;

  static const List<WardrobeItemType> all = [
    WardrobeItemType(zh: '上衣', en: 'top'),
    WardrobeItemType(zh: '褲子', en: 'pants'),
    WardrobeItemType(zh: '裙子', en: 'skirt'),
    WardrobeItemType(zh: '外套', en: 'jacket'),
    WardrobeItemType(zh: '鞋子', en: 'shoes'),
    WardrobeItemType(zh: '配件', en: 'accessories'),
    WardrobeItemType(zh: '其他', en: 'others'),
  ];
}

class WardrobeItem {
  WardrobeItem({
    this.id,
    required this.imagePath,
    required this.category,
    this.tags = const [],
  });

  factory WardrobeItem.fromJson(final Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'],
      imagePath: json['image_path'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
    );
  }

  final String? id;
  final String imagePath;
  final String category;
  final List<String> tags;

  Map<String, dynamic> toJson() {
    return {'id': id, 'image_path': imagePath, 'category': category, 'tags': tags};
  }

  // 按需載入圖片，使用快取機制
  Future<Result<File>> loadImage() async {
    return WardrobeService.getWardrobeItemImage(imagePath);
  }
}
