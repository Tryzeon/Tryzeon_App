import 'package:flutter/material.dart';

/// 身型測量欄位定義
enum MeasurementType {
  height('身高 (cm)', 'height', Icons.height_rounded),
  weight('體重 (kg)', 'weight', Icons.monitor_weight_outlined),
  chest('胸圍 (cm)', 'chest', Icons.accessibility_rounded),
  waist('腰圍 (cm)', 'waist', Icons.accessibility_rounded),
  hips('臀圍 (cm)', 'hips', Icons.accessibility_rounded),
  shoulderWidth('肩寬 (cm)', 'shoulder_width', Icons.accessibility_rounded),
  sleeveLength('袖長 (cm)', 'sleeve_length', Icons.accessibility_rounded);

  const MeasurementType(this.label, this.key, this.icon);
  final String label;
  final IconData icon;
  final String key;
}
