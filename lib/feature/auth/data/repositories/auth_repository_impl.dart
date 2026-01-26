import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_local_data_source.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required final AuthRemoteDataSource remoteDataSource,
    required final AuthLocalDataSource localDataSource,
    required final CacheService cacheService,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _cacheService = cacheService;
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final CacheService _cacheService;

  @override
  Future<Result<void, String>> signInWithProvider({
    required final String provider,
    required final UserType userType,
  }) async {
    try {
      // Map provider string to OAuthProvider
      final OAuthProvider oauthProvider;
      switch (provider.toLowerCase()) {
        case 'google':
          oauthProvider = OAuthProvider.google;
          break;
        case 'facebook':
          oauthProvider = OAuthProvider.facebook;
          break;
        case 'apple':
          oauthProvider = OAuthProvider.apple;
          break;
        default:
          return Err('目前不支援 $provider 登入');
      }

      if (oauthProvider == OAuthProvider.apple && Platform.isIOS) {
        await _remoteDataSource.signInWithAppleNative();
      } else {
        await _remoteDataSource.signInWithOAuthProvider(oauthProvider);
      }

      // Store login type preference
      await _localDataSource.setLastLoginType(userType.name);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('$provider 登入失敗', e, stackTrace);
      return Err('$provider 登入失敗，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> signOut() async {
    // Sign out from Supabase
    try {
      await _remoteDataSource.signOut();
    } catch (e, stackTrace) {
      AppLogger.error('Supabase 登出失敗 (已忽略)', e, stackTrace);
    }

    // Clear API cache
    try {
      await _cacheService.clearCache();
    } catch (e, stackTrace) {
      AppLogger.error('清除快取失敗 (已忽略)', e, stackTrace);
    }

    // Clear local preferences
    try {
      await _localDataSource.clearAll();
    } catch (e, stackTrace) {
      AppLogger.error('清除登入類型失敗 (已忽略)', e, stackTrace);
    }

    return const Ok(null);
  }

  @override
  Future<Result<UserType?, String>> getLastLoginType() async {
    try {
      final typeString = await _localDataSource.getLastLoginType();
      if (typeString == null) return const Ok(null);

      final userType = UserType.values.firstWhere(
        (final type) => type.name == typeString,
        orElse: () => UserType.personal,
      );

      return Ok(userType);
    } catch (e, stackTrace) {
      AppLogger.error('取得登入類型失敗', e, stackTrace);
      return const Err('取得登入類型失敗');
    }
  }

  @override
  Future<Result<void, String>> setLastLoginType(final UserType userType) async {
    try {
      await _localDataSource.setLastLoginType(userType.name);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('儲存登入類型失敗', e, stackTrace);
      return const Err('儲存登入類型失敗');
    }
  }

  @override
  Future<Result<void, String>> sendEmailOtp({
    required final String email,
    required final UserType userType,
  }) async {
    try {
      await _remoteDataSource.sendEmailOTP(email);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('發送 Email OTP 失敗', e, stackTrace);
      return const Err('發送登入連結失敗，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> verifyEmailOtp({
    required final String email,
    required final String token,
    required final UserType userType,
  }) async {
    try {
      await _remoteDataSource.verifyEmailOTP(email: email, token: token);
      await _localDataSource.setLastLoginType(userType.name);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Email OTP 驗證失敗', e, stackTrace);
      return const Err('驗證碼無效或已過期，請重新發送');
    }
  }
}
