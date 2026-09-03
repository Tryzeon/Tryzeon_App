import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/body_measurements/presentation/mappers/body_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';

/// UI display extensions for [FitResult] in Presentation Layer.
///
/// Maps the domain entity into headline / subline / icon for both
/// [SizeAdvisorBanner] (bordered card) and the inline fit row inside
/// [PrePurchaseSheet]. Lives at the presentation layer because Material
/// `IconData` and Chinese display strings are presentation concerns.
extension FitResultUiMapper on FitResult {
  String get headline {
    switch (displayState) {
      case FitDisplayState.match:
        return alternativeSize != null
            ? '您的尺寸：$recommendedSize（也適合 $alternativeSize）'
            : '您的尺寸：$recommendedSize';
      case FitDisplayState.caveats:
        return '您的尺寸：$recommendedSize（部分匹配）';
      case FitDisplayState.outOfRange:
        return '此商品暫無您的尺寸';
      case FitDisplayState.noUserData:
        return '尚未輸入身形';
      case FitDisplayState.unknown:
        return '';
    }
  }

  String get subline {
    switch (displayState) {
      case FitDisplayState.match:
        if (matchedTypes.length == 1) return '${matchedTypes.first.label}合身';
        return '${matchedTypes.map((final t) => t.label).join('、')}皆合身';
      case FitDisplayState.caveats:
        return caveats
            .map(
              (final c) =>
                  '${c.type.label}${c.direction == FitDirection.tight ? '偏緊' : '偏鬆'} '
                  '${c.deviation.toStringAsFixed(1)}cm',
            )
            .join('、');
      case FitDisplayState.outOfRange:
        return '可試穿看看商品效果';
      case FitDisplayState.noUserData:
        return '輸入您的身形即可自動計算合身尺寸';
      case FitDisplayState.unknown:
        return '';
    }
  }

  IconData get iconData => switch (displayState) {
    FitDisplayState.match => Icons.check_rounded,
    FitDisplayState.caveats => Icons.contrast_rounded,
    FitDisplayState.outOfRange => Icons.remove_rounded,
    FitDisplayState.noUserData => Icons.straighten_rounded,
    FitDisplayState.unknown => Icons.help_outline,
  };
}
