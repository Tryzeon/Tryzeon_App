import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/core/error/exceptions.dart';

class StoreImagesApi {
  StoreImagesApi(this._supabaseClient, [final Dio? dio]) : _dio = dio ?? Dio();

  final SupabaseClient _supabaseClient;
  final Dio _dio;

  static String publicUrl(final String key) => '${Env.r2PublicImagesBaseUrl}/$key';

  Future<String> uploadStoreLogo({
    required final String storeId,
    required final File logo,
  }) async {
    final contentType = lookupMimeType(logo.path) ?? 'image/jpeg';
    final bytes = await logo.readAsBytes();

    final response = await _supabaseClient.functions.invoke(
      AppConstants.functionStoreImagesPresignLogo,
      body: {
        'storeId': storeId,
        'contentType': contentType,
        'contentLength': bytes.length,
      },
    );
    final presign = Map<String, dynamic>.from(response.data as Map);
    final key = presign['key'] as String;
    final uploadUrl = presign['uploadUrl'] as String;

    await _putToR2(uploadUrl: uploadUrl, bytes: bytes, contentType: contentType);
    return key;
  }

  Future<List<String>> uploadProductImages({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  }) async {
    if (images.isEmpty) return const [];

    final contentTypes = images
        .map((final f) => lookupMimeType(f.path) ?? 'image/jpeg')
        .toList();
    final allBytes = await Future.wait(images.map((final f) => f.readAsBytes()));

    final response = await _supabaseClient.functions.invoke(
      AppConstants.functionStoreImagesPresignProducts,
      body: {
        'storeId': storeId,
        'productId': productId,
        'files': List.generate(
          images.length,
          (final i) => {
            'contentType': contentTypes[i],
            'contentLength': allBytes[i].length,
          },
        ),
      },
    );
    final presign = Map<String, dynamic>.from(response.data as Map);
    final items = (presign['items'] as List).cast<Map<String, dynamic>>();
    if (items.length != images.length) {
      throw const ServerException(
        'store-images: presign returned wrong number of items',
        500,
      );
    }

    final keys = await Future.wait(
      List.generate(images.length, (final i) async {
        await _putToR2(
          uploadUrl: items[i]['uploadUrl'] as String,
          bytes: allBytes[i],
          contentType: contentTypes[i],
        );
        return items[i]['key'] as String;
      }),
    );
    return keys;
  }

  Future<void> deleteImages({
    required final String storeId,
    required final List<String> keys,
  }) async {
    if (keys.isEmpty) return;
    await _supabaseClient.functions.invoke(
      AppConstants.functionStoreImagesDelete,
      body: {'storeId': storeId, 'keys': keys},
    );
  }

  Future<void> _putToR2({
    required final String uploadUrl,
    required final Uint8List bytes,
    required final String contentType,
  }) async {
    await _dio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(contentType: contentType),
    );
  }
}
