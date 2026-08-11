import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static final String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static final String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'REVENUE_CAT_API_KEY')
  static final String revenueCatApiKey = _Env.revenueCatApiKey;

  @EnviedField(varName: 'R2_PUBLIC_IMAGES_BASE_URL')
  static final String r2PublicImagesBaseUrl = _Env.r2PublicImagesBaseUrl;
}
