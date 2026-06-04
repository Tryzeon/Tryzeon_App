import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/utils/app_logger.dart';

import '../entities/label_result.dart';
import '../services/background_remover.dart';
import '../services/label_tagger.dart';

class AnalyzeWardrobeImage {
  AnalyzeWardrobeImage({
    required final LabelTagger labelTagger,
    required final BackgroundRemover backgroundRemover,
  }) : _labelTagger = labelTagger,
       _backgroundRemover = backgroundRemover;

  final LabelTagger _labelTagger;
  final BackgroundRemover _backgroundRemover;

  Future<LabelResult> labels(final File image) async {
    try {
      return await _labelTagger.analyze(image);
    } catch (e, st) {
      AppLogger.warning('label tagging failed', e, st);
      return const LabelResult();
    }
  }

  Future<Uint8List?> removeBackground(final File image) async {
    try {
      return await _backgroundRemover.remove(image);
    } catch (e, st) {
      AppLogger.warning('background removal failed', e, st);
      return null;
    }
  }
}
