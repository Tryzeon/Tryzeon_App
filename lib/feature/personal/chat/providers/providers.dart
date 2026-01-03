import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/repositories/chat_repository_impl.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:tryzeon/feature/personal/chat/domain/usecases/get_llm_recommendation.dart';

// Data Source Provider
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((final ref) {
  return ChatRemoteDataSource(Supabase.instance.client);
});

// Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((final ref) {
  final remoteDataSource = ref.read(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Case Provider
final getLLMRecommendationUseCaseProvider = Provider<GetLLMRecommendationUseCase>((
  final ref,
) {
  final repository = ref.read(chatRepositoryProvider);
  return GetLLMRecommendationUseCase(repository);
});
