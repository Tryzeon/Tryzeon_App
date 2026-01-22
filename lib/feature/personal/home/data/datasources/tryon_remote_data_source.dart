import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class TryonRemoteDataSource {
  TryonRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  Future<String> tryon({
    final String? avatarBase64,
    final String? avatarPath,
    final String? clothesBase64,
    final String? clothesPath,
  }) async {
    final Map<String, dynamic> body = {};
    body['avatarBase64'] = avatarBase64;
    body['avatarPath'] = avatarPath;
    body['clothesBase64'] = clothesBase64;
    body['clothesPath'] = clothesPath;

    final response = await _supabase.functions.invoke(
      AppConstants.functionTryon,
      body: body,
    );
    return response.data['image'] as String;
  }
}
