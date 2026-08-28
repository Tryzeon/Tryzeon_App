import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';

GarmentMeasurementType? _typeFromKey(final String key) {
  for (final t in GarmentMeasurementType.values) {
    if (t.value == key) return t;
  }
  return null;
}

MeasurementUnit _unitFromString(final Object? value) {
  return switch (value) {
    'cun' => MeasurementUnit.cun,
    'inch' => MeasurementUnit.inch,
    _ => MeasurementUnit.centimeter,
  };
}

double? _toDouble(final Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<ParsedSize> parseSizeVoiceResponse(final Map<String, dynamic> data) {
  final rawSizes = data['sizes'];
  if (rawSizes is! List) return [];

  final result = <ParsedSize>[];
  for (final rawSize in rawSizes) {
    if (rawSize is! Map) continue;
    final name = rawSize['name'] is String ? rawSize['name'] as String : '';
    final measurements = <GarmentMeasurementType, ParsedMeasurement>{};
    final rawMeasurements = rawSize['measurements'];
    if (rawMeasurements is Map) {
      rawMeasurements.forEach((final key, final value) {
        final type = key is String ? _typeFromKey(key) : null;
        if (type == null || value is! Map) return;
        final v = _toDouble(value['value']);
        if (v == null) return;
        measurements[type] = ParsedMeasurement(
          value: v,
          unit: _unitFromString(value['unit']),
        );
      });
    }
    result.add(ParsedSize(name: name, measurements: measurements));
  }
  return result;
}

class SizeVoiceParser {
  SizeVoiceParser(this._supabase);

  final SupabaseClient _supabase;
  static const _timeout = Duration(seconds: 30);

  Future<List<ParsedSize>> parse({
    required final Uint8List audioBytes,
    required final String mimeType,
    required final MeasurementUnit currentUnit,
  }) async {
    final base64Audio = base64Encode(audioBytes);
    final response = await _supabase.functions
        .invoke(
          AppConstants.functionParseSizeVoice,
          body: {
            'audioBase64': base64Audio,
            'mimeType': mimeType,
            'currentUnit': currentUnit.name,
          },
        )
        .timeout(_timeout);

    final data = response.data;
    return data is Map<String, dynamic> ? parseSizeVoiceResponse(data) : [];
  }
}
