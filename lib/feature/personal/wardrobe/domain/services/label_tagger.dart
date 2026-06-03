import 'dart:io';

import '../entities/label_result.dart';

abstract interface class LabelTagger {
  Future<LabelResult> analyze(final File image);
}
